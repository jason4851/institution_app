import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

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
  void initState(){
    super.initState();
    _setupCameraController();
  }


  Future<void> _captureFace()async{
    if (cameraController == null || cameraController?.value.isInitialized == false) {
      return;
    }
    try{
      XFile picture = await cameraController!.takePicture();
      File pictureFile = File(picture.path);
      await _detectFace(File(pictureFile.path));
      print("Detected Face: ${picture.path}");
    }
    catch(e){
      print("Error in face detection: $e");
    }
  }
  
  Future<void> _detectFace(File imageFile) async{
    try{
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.0.187:5001/match_face')
      );

      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      request.fields['institution_id'] = widget.institution_id;
      var response = await request.send();  
      if (response.statusCode == 200) {
        print("Face detection successful");
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
        title: Text('Check In'),
      ),
  );

}
Widget _buildUI(){
  if (cameraController == null || cameraController?.value.isInitialized == false){
    return const Center(child: CircularProgressIndicator(),);
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
          height: MediaQuery.sizeOf(context).height*0.65,
          width: MediaQuery.sizeOf(context).width,
          child: CameraPreview(
            cameraController!,
          ),
          )

        ),

      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(),
          ),
            IconButton(
            onPressed: () => _captureFace(),
            iconSize: 90,
            icon: const Icon(
            Icons.camera,
            color: Colors.red,
            ), 
          
          ),
          Expanded(child: Align(
            alignment: Alignment.center,
            child :IconButton(
            icon: const Icon(Icons.flip_camera_ios, size: 50),
            onPressed: _switchCamera, 
           ),
            ),),
  
            
          
      
        ],
      ),


        
      ],
    ),
  ),
  );
}

 Future<void> _setupCameraController() async {
    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      cameraController = CameraController(
        cameras[selectedCameraIndex],
        ResolutionPreset.max,
      );
      await cameraController?.initialize();
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _switchCamera() {
    if (cameras.isNotEmpty) {
      selectedCameraIndex = (selectedCameraIndex + 1) % 2;
      _setupCameraController();
    }
  }
}
