library permission_service;

import 'package:permission_handler/permission_handler.dart';
import '../core/exceptions/app_exceptions.dart';
import '../core/logging/app_logger.dart';

/// Centralized service for handling app permissions
class PermissionService {
  /// Request camera permission
  static Future<bool> requestCamera() async {
    try {
      final status = await Permission.camera.request();
      final granted = status.isGranted;
      AppLogger.permission('Camera', granted);
      
      if (!granted) {
        if (status.isPermanentlyDenied) {
          throw PermissionException(
            'Camera',
            'Camera permission is permanently denied. Please enable it in app settings.',
            code: 'PERMANENTLY_DENIED',
          );
        }
        throw PermissionException(
          'Camera',
          'Camera permission is required to take photos.',
          code: 'DENIED',
        );
      }
      
      return true;
    } catch (e) {
      if (e is PermissionException) rethrow;
      AppLogger.error('Failed to request camera permission', error: e, tag: 'PermissionService');
      throw PermissionException('Camera', 'Failed to request camera permission: $e', originalError: e);
    }
  }

  /// Request storage permission (for Android)
  static Future<bool> requestStorage() async {
    try {
      // For Android 13+, use photos permission
      // For older versions, use storage permission
      final status = await Permission.photos.request();
      final granted = status.isGranted;
      AppLogger.permission('Storage/Photos', granted);
      
      if (!granted) {
        if (status.isPermanentlyDenied) {
          throw PermissionException(
            'Storage',
            'Storage permission is permanently denied. Please enable it in app settings.',
            code: 'PERMANENTLY_DENIED',
          );
        }
        throw PermissionException(
          'Storage',
          'Storage permission is required to save and access photos.',
          code: 'DENIED',
        );
      }
      
      return true;
    } catch (e) {
      if (e is PermissionException) rethrow;
      AppLogger.error('Failed to request storage permission', error: e, tag: 'PermissionService');
      throw PermissionException('Storage', 'Failed to request storage permission: $e', originalError: e);
    }
  }

  /// Request all required permissions for the app
  static Future<bool> requestAllPermissions() async {
    try {
      final cameraGranted = await requestCamera();
      final storageGranted = await requestStorage();
      
      return cameraGranted && storageGranted;
    } catch (e) {
      AppLogger.error('Failed to request all permissions', error: e, tag: 'PermissionService');
      rethrow;
    }
  }

  /// Check if camera permission is granted
  static Future<bool> isCameraGranted() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      AppLogger.error('Failed to check camera permission status', error: e, tag: 'PermissionService');
      return false;
    }
  }

  /// Check if storage permission is granted
  static Future<bool> isStorageGranted() async {
    try {
      final status = await Permission.photos.status;
      return status.isGranted;
    } catch (e) {
      AppLogger.error('Failed to check storage permission status', error: e, tag: 'PermissionService');
      return false;
    }
  }

  /// Open app settings for permission configuration
  static Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      AppLogger.error('Failed to open app settings', error: e, tag: 'PermissionService');
      return false;
    }
  }
}
