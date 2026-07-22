library api_config;

/// API Configuration for GuaverRoots
/// 
/// Configure your FastAPI backend URL here.
/// The app will use this URL for API calls when online.
import '../core/constants/app_constants.dart';

class ApiConfig {
  /// Base URL for the FastAPI backend
  /// Note: 10.0.2.2 is the Android emulator's alias for host localhost.
  /// For physical devices, use your machine's actual IP address or deployed backend URL.
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  /// API Endpoints
  static const String analyzeEndpoint = '/analyze';
  static const String analyzeAreaEndpoint = '/analyze-area';
  
  /// Connection timeout duration
  static const int connectionTimeoutSeconds = AppConstants.connectionTimeoutSeconds;
  
  /// Receive timeout duration
  static const int receiveTimeoutSeconds = AppConstants.receiveTimeoutSeconds;
}
