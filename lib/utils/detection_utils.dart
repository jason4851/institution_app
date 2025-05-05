import 'package:eyeblinkdetectface/index.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:collection/collection.dart';

class DetectionUtils {
  static Future<void> detect({
    required Face face,
    required M7LivelynessStep step,
    required Function(M7LivelynessStep) onCompleteStep,
    required Function() onStartProcessing,
    required Function() onSetDidCloseEyes,
  }) async {
    if (step == M7LivelynessStep.blink) {
      final M7BlinkDetectionThreshold? blinkThreshold =
      Eyeblinkdetectface.instance.thresholdConfig.firstWhereOrNull(
            (p0) => p0 is M7BlinkDetectionThreshold,
      ) as M7BlinkDetectionThreshold?;
      if ((face.leftEyeOpenProbability ?? 1.0) <
          (blinkThreshold?.leftEyeProbability ?? 0.25) &&
          (face.rightEyeOpenProbability ?? 1.0) <
              (blinkThreshold?.rightEyeProbability ?? 0.25)) {
        onStartProcessing();
        onSetDidCloseEyes();
      }
    } else if (step == M7LivelynessStep.turnLeft) {
      final M7HeadTurnDetectionThreshold? headTurnThreshold =
      Eyeblinkdetectface.instance.thresholdConfig.firstWhereOrNull(
            (p0) => p0 is M7HeadTurnDetectionThreshold,
      ) as M7HeadTurnDetectionThreshold?;
      if ((face.headEulerAngleY ?? 0) >
          (headTurnThreshold?.rotationAngle ?? 45)) {
        onStartProcessing();
        await onCompleteStep(step);
      }
    } else if (step == M7LivelynessStep.turnRight) {
      final M7HeadTurnDetectionThreshold? headTurnThreshold =
      Eyeblinkdetectface.instance.thresholdConfig.firstWhereOrNull(
            (p0) => p0 is M7HeadTurnDetectionThreshold,
      ) as M7HeadTurnDetectionThreshold?;
      if ((face.headEulerAngleY ?? 0) <
          (headTurnThreshold?.rotationAngle ?? -50)) {
        onStartProcessing();
        await onCompleteStep(step);
      }
    } else if (step == M7LivelynessStep.smile) {
      final M7SmileDetectionThreshold? smileThreshold =
      Eyeblinkdetectface.instance.thresholdConfig.firstWhereOrNull(
            (p0) => p0 is M7SmileDetectionThreshold,
      ) as M7SmileDetectionThreshold?;
      if ((face.smilingProbability ?? 0) >
          (smileThreshold?.probability ?? 0.75)) {
        onStartProcessing();
        await onCompleteStep(step);
      }
    }
  }
}