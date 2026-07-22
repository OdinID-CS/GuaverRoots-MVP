library app_exceptions;

/// Base exception class for all app-specific exceptions
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message${code != null ? " (Code: $code)" : ""}';
}

/// Exception thrown when camera initialization fails
class CameraException extends AppException {
  CameraException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception thrown when image capture fails
class ImageCaptureException extends AppException {
  ImageCaptureException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception thrown when API request fails
class ApiException extends AppException {
  final int? statusCode;

  ApiException(String message, {this.statusCode, String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'ApiException: $message${statusCode != null ? " (Status: $statusCode)" : ""}';
}

/// Exception thrown when network is unavailable
class NetworkException extends AppException {
  NetworkException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception thrown when storage operations fail
class StorageException extends AppException {
  StorageException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception thrown when permission is denied
class PermissionException extends AppException {
  final String permissionType;

  PermissionException(this.permissionType, String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'PermissionException: $permissionType - $message';
}

/// Exception thrown when image compression fails
class CompressionException extends AppException {
  CompressionException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}
