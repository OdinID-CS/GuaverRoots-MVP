library app_logger;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Log levels for structured logging
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Structured logging service for the application
class AppLogger {
  static const String _tag = 'GuaverRoots';
  static bool _enableDebugLogging = kDebugMode;

  /// Enable or disable debug logging
  static void setDebugLogging(bool enabled) {
    _enableDebugLogging = enabled;
  }

  /// Log debug message
  static void debug(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    _log(LogLevel.debug, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  /// Log info message
  static void info(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    _log(LogLevel.info, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  /// Log warning message
  static void warning(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    _log(LogLevel.warning, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  /// Log error message
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  /// Log critical message
  static void critical(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    _log(LogLevel.critical, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  /// Internal logging method
  static void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (!_enableDebugLogging && level == LogLevel.debug) {
      return;
    }

    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
    final levelStr = level.name.toUpperCase();
    final tagStr = tag ?? _tag;
    final logMessage = '[$timestamp] [$levelStr] [$tagStr] $message';

    switch (level) {
      case LogLevel.debug:
        debugPrint(logMessage);
        break;
      case LogLevel.info:
        debugPrint(logMessage);
        break;
      case LogLevel.warning:
        debugPrint('⚠️  $logMessage');
        break;
      case LogLevel.error:
        debugPrint('❌ $logMessage');
        if (error != null) {
          debugPrint('   Error: $error');
        }
        if (stackTrace != null) {
          debugPrint('   StackTrace: $stackTrace');
        }
        break;
      case LogLevel.critical:
        debugPrint('🚨 $logMessage');
        if (error != null) {
          debugPrint('   Error: $error');
        }
        if (stackTrace != null) {
          debugPrint('   StackTrace: $stackTrace');
        }
        break;
    }
  }

  /// Log API request
  static void apiRequest(String method, String endpoint, {Map<String, dynamic>? data}) {
    final dataStr = data != null ? ' | Data: $data' : '';
    info('API Request: $method $endpoint$dataStr', tag: 'API');
  }

  /// Log API response
  static void apiResponse(String method, String endpoint, int statusCode, {dynamic data}) {
    final dataStr = data != null ? ' | Response: $data' : '';
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final logFunc = isSuccess ? info : warning;
    logFunc('API Response: $method $endpoint | Status: $statusCode$dataStr', tag: 'API');
  }

  /// Log API error
  static void apiError(String method, String endpoint, String errorMessage, {int? statusCode}) {
    final statusStr = statusCode != null ? ' | Status: $statusCode' : '';
    error('API Error: $method $endpoint$statusStr | Error: $errorMessage', tag: 'API');
  }

  /// Log storage operation
  static void storage(String operation, String key, {bool success = true}) {
    final status = success ? '✓' : '✗';
    final logFunc = success ? debug : error;
    logFunc('$status Storage $operation: $key', tag: 'Storage');
  }

  /// Log camera operation
  static void camera(String operation, {bool success = true, String? details}) {
    final status = success ? '✓' : '✗';
    final detailsStr = details != null ? ' | $details' : '';
    final logFunc = success ? debug : error;
    logFunc('$status Camera $operation$detailsStr');
  }

  /// Log permission request
  static void permission(String permission, bool granted) {
    final status = granted ? '✓ Granted' : '✗ Denied';
    final logFunc = granted ? info : warning;
    logFunc('$status: $permission', tag: 'Permission');
  }
}
