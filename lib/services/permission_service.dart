import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+
        Map<Permission, PermissionStatus> statuses = await [
          Permission.photos,
          Permission.videos,
          Permission.camera,
        ].request();

        return statuses.values.every((status) => status.isGranted);
      } else {
        // Android < 13
        Map<Permission, PermissionStatus> statuses = await [
          Permission.storage,
          Permission.camera,
        ].request();

        return statuses.values.every((status) => status.isGranted);
      }
    } else if (Platform.isIOS) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.photos,
        Permission.camera,
      ].request();

      return statuses.values.every((status) => status.isGranted);
    }

    return true;
  }

  static Future<bool> checkPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        return await Permission.photos.isGranted &&
            await Permission.videos.isGranted;
      } else {
        return await Permission.storage.isGranted;
      }
    }
    return await Permission.photos.isGranted;
  }
}
