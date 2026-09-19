import 'package:permission_handler/permission_handler.dart';

class CameraPermissionManager {
  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    print('[CameraPermission] Current status: $status');
    return status.isGranted;
  }

  static Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    print('[CameraPermission] Microphone status: $status');
    return status.isGranted;
  }

  static Future<PermissionStatus> requestCameraPermission() async {
    print('[CameraPermission] Requesting camera permission...');
    final status = await Permission.camera.request();
    print('[CameraPermission] Permission request result: $status');
    return status;
  }

  static Future<PermissionStatus> requestMicrophonePermission() async {
    print('[CameraPermission] Requesting microphone permission...');
    final status = await Permission.microphone.request();
    print('[CameraPermission] Microphone request result: $status');
    return status;
  }

  static Future<bool> ensureCameraPermission() async {
    final granted = await checkCameraPermission();
    if (granted) {
      print('[CameraPermission] Camera permission already granted');
      return true;
    }

    print('[CameraPermission] Camera permission not granted, requesting...');
    final status = await requestCameraPermission();

    if (status.isDenied) {
      print('[CameraPermission] Permission denied by user');
      return false;
    }

    if (status.isPermanentlyDenied) {
      print('[CameraPermission] Permission permanently denied, opening settings...');
      openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  static Future<bool> ensureMicrophonePermission() async {
    final granted = await checkMicrophonePermission();
    if (granted) {
      print('[CameraPermission] Microphone permission already granted');
      return true;
    }

    print('[CameraPermission] Microphone permission not granted, requesting...');
    final status = await requestMicrophonePermission();

    if (status.isDenied) {
      print('[CameraPermission] Microphone permission denied by user');
      return false;
    }

    if (status.isPermanentlyDenied) {
      print('[CameraPermission] Microphone permission permanently denied, opening settings...');
      openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  static Future<bool> ensureAllMediaPermissions() async {
    final camera = await ensureCameraPermission();
    final microphone = await ensureMicrophonePermission();
    return camera && microphone;
  }

  static String getPermissionStatusMessage(PermissionStatus status) {
    if (status.isGranted) return 'Izin diberikan';
    if (status.isDenied) return 'Izin ditolak';
    if (status.isPermanentlyDenied) return 'Izin diblokir. Buka pengaturan untuk mengizinkan.';
    if (status.isRestricted) return 'Izin dibatasi';
    if (status.isLimited) return 'Izin terbatas';
    return 'Status izin tidak diketahui';
  }
}
