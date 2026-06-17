import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermissionService {
  AppPermissionService._();

  static Future<bool> requestPhotos() async {
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return _request(Permission.photos);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final photos = await Permission.photos.request();
      if (photos.isGranted || photos.isLimited) return true;
      final storage = await Permission.storage.request();
      return storage.isGranted || storage.isLimited;
    }
    return true;
  }

  static Future<bool> requestCamera() async {
    if (kIsWeb) return true;
    return _request(Permission.camera);
  }

  /// En móvil guardamos en almacenamiento de la app/cache, así que no bloqueamos
  /// la descarga si Android no concede almacenamiento amplio.
  static Future<bool> requestDownloads() async {
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.storage.request();
      return status.isGranted ||
          status.isLimited ||
          status.isDenied ||
          status.isPermanentlyDenied;
    }
    return true;
  }

  static Future<bool> _request(Permission permission) async {
    final current = await permission.status;
    if (current.isGranted || current.isLimited) return true;
    final next = await permission.request();
    return next.isGranted || next.isLimited;
  }
}
