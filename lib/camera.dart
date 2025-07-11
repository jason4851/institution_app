import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:eyeblinkdetectface/index.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:institution_app/utils/detection_utils.dart';
import 'package:flutter/services.dart';

class Camera  extends StatefulWidget{
  final String institution_id;
  const Camera({super.key, required this.institution_id});


  @override
  State<Camera> createState() => _CameraState();

}

class _CameraState extends State<Camera> with WidgetsBindingObserver{
  List<CameraDescription> cameras = [];
  CameraController? cameraController;
  int selectedCameraIndex = 0;
  bool _isCapturingBurst = false;
  bool _isProcessing = false;
  bool _isBusy = false;
  bool _didCloseEyes = false;
  bool _face_detected = false;
  String _detect_text = '';
  late FaceDetector faceDetector;
  final List<M7LivelynessStepItem> _verificationSteps = [];
  DateTime _lastFrameProcessed = DateTime.now();  

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if(cameraController == null || cameraController?.value.isInitialized ==false){
      return;
    }
    if(state == AppLifecycleState.inactive){
      cameraController?.dispose();
    }else if(state == AppLifecycleState.resumed){
      _setupCameraController();
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    faceDetector.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void initState(){
    super.initState();
    _initValues();
    _setupCameraController();
    WidgetsBinding.instance.addObserver(this);
    faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
      )
    );
  }

  void _initValues(){
    _verificationSteps.clear();
    _verificationSteps.add(
      M7LivelynessStepItem(
        step: M7LivelynessStep.blink,
        title: "Blink to Capture",
        isCompleted: false,
      ),
    );
    Eyeblinkdetectface.instance.configure(
      contourColor: Colors.blue,
      thresholds: [
        M7BlinkDetectionThreshold(
          leftEyeProbability: 0.15,
          rightEyeProbability: 0.15,
        ),
      ]
    );
  }

  Future<void> _setupCameraController() async{
    try{
      cameras = await availableCameras();
      if(cameras.isNotEmpty){
        cameraController = CameraController(
          cameras[selectedCameraIndex],
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
        );
        await cameraController?.initialize();
        if(mounted){
          setState((){});
          cameraController?.startImageStream(_processCameraImage);
        }
      }

    }catch(e){
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Camera initialization failed: $e"),
          ),
        );
      }
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || _verificationSteps[0].isCompleted) return;

    final now = DateTime.now();
    if (now.difference(_lastFrameProcessed).inMilliseconds < 100) return;

    _isBusy = true;
    try {
      _lastFrameProcessed = now;
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final faces = await faceDetector.processImage(inputImage);
      if (faces.isNotEmpty) {
        final face = faces.first;
        DetectionUtils.detect(
          face: faces.first,
          step: M7LivelynessStep.blink,
          onCompleteStep: (step) async {
            _verificationSteps[0] = _verificationSteps[0].copyWith(isCompleted: true);
            //await _takePicture();
          },
          onStartProcessing: () {
            // setState(() {
            //   _isProcessing = true;
            // });
          },
          onSetDidCloseEyes: () {
            if(!_didCloseEyes){
              Future.microtask(() => setState(() => _didCloseEyes = true));
            }
          },
        );
        final left = face.leftEyeOpenProbability ?? 1.0;
        final right = face.rightEyeOpenProbability ?? 1.0;
        //upon finding out they closed eyes and eyes are open, opens blinking and takes pictures
        if (_didCloseEyes && left > 0.75 && right > 0.75) {
          setState(() {
            _didCloseEyes = false;
            _takePicture();
          });
        }
      }
    } finally {
      _isBusy = false;
    }
}

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (cameraController == null) return null;
    final camera = cameras[selectedCameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      final orientation = {
        DeviceOrientation.portraitUp: 0,
        DeviceOrientation.landscapeLeft: 90,
        DeviceOrientation.portraitDown: 180,
        DeviceOrientation.landscapeRight: 270,
      }[cameraController!.value.deviceOrientation] ?? 0;
      rotation = InputImageRotationValue.fromRawValue(
        camera.lensDirection == CameraLensDirection.front
            ? (sensorOrientation + orientation) % 360
            : (sensorOrientation - orientation + 360) % 360,
      );
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }
    try{
      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in image.planes){
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }
    catch (e) {
      print("Failed to convert image: $e");
      return null;
    }
  }
  
  void _switchCamera() async {
    if(cameras.length > 1){
      selectedCameraIndex = (selectedCameraIndex + 1) % cameras.length;
      if(cameraController != null){
        await cameraController!.dispose();
      }
      _setupCameraController();
    }
  }

  Future<void> _takePicture() async {
    print("Blink found, taking picture");
    if (cameraController == null || !cameraController!.value.isInitialized) return;
    setState(() => _isProcessing = true);
    try {
      await cameraController?.stopImageStream();
      final XFile image = await cameraController!.takePicture();
      File pictureFile = File(image.path);
      await _detectFace(pictureFile);
      print("Photo Saved: ${image.path}");
    } catch (e) {
      print("Error capturing photo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }
  Future<void> _uploadImages(File imageFile, String uid) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.232.232.108:5001/upload'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      request.fields['uid'] = uid;
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print("Response Status: ${response.statusCode}");
      print("Response Body: $responseBody");
      if (response.statusCode == 200) {
        print("Upload successful!");
      } else {
        print("Upload failed: ${response.reasonPhrase}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: ${response.reasonPhrase ?? "Unknown error"}')),
          );
        }
      }
    } catch (e) {
      print("Error uploading image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }

  }


  
  Future<void> _detectFace(File imageFile) async{
    try{
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.232.232.108:5001/match_face')
      );

      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      request.fields['institution_id'] = widget.institution_id;
      var response = await request.send();  
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString(); 
        final data = jsonDecode(responseBody);
        final Map<String, dynamic> user = data["user"];
        final String firstName = user["first_name"];
        print("Face detection successful");
        setState(() {
          _face_detected = true;
          _detect_text = "$firstName, Welcome";
        });
      }
      else {
        final respStr = await response.stream.bytesToString();
        print('Error Body: $respStr');
        setState((){});
        cameraController?.startImageStream(_processCameraImage);
      }
    }
    catch(e){
      print("Error in face detection: $e");
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: _buildUI(),
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Blink to Detect Face'),
      ),
  );

}
Widget _buildUI(){
  if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return SafeArea(
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.fitWidth,
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.65,
                width: MediaQuery.sizeOf(context).width,
                child: CameraPreview(cameraController!),
              ),
            ),
            if (_isProcessing)
              const CircularProgressIndicator()
            else
              Text(
                _face_detected? _detect_text : '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: Container()),
                if (cameras.length > 1)
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios, size: 50),
                    onPressed: _isProcessing ? null : _switchCamera,
                  )
                else
                  Expanded(child: Container()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
