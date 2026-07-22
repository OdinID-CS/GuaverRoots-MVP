import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/scan_result.dart';
import '../config/api_config.dart';
import '../data/mock_disease_data.dart';
import '../core/logging/app_logger.dart';
import '../core/constants/app_constants.dart';

class ApiService extends ChangeNotifier {
  final Dio _dio = Dio();
  bool _isOnline = true;

  ApiService() {
    _initConnectivity();
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: AppConstants.connectionTimeoutSeconds);
    _dio.options.receiveTimeout = const Duration(seconds: AppConstants.receiveTimeoutSeconds);
    AppLogger.info('ApiService initialized', tag: 'ApiService');
  }

  bool get isOnline => _isOnline;

  Future<void> _initConnectivity() async {
    final connectivity = Connectivity();
    connectivity.onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      AppLogger.info('Connectivity changed: ${_isOnline ? "Online" : "Offline"}', tag: 'ApiService');
      notifyListeners();
    });
  }

  Future<ScanResult?> analyzeImage(String imagePath) async {
    if (!_isOnline) {
      AppLogger.info('Offline mode: Using mock disease data', tag: 'ApiService');
      return _getMockResult(imagePath);
    }

    try {
      AppLogger.apiRequest('POST', ApiConfig.analyzeEndpoint);
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dio.post(ApiConfig.analyzeEndpoint, data: formData);
      
      if (response.statusCode == 200) {
        AppLogger.apiResponse('POST', ApiConfig.analyzeEndpoint, response.statusCode ?? 0, data: response.data);
        return ScanResult.fromJson(response.data);
      } else {
        AppLogger.apiError('POST', ApiConfig.analyzeEndpoint, 'Unexpected status code', statusCode: response.statusCode);
      }
    } catch (e) {
      AppLogger.apiError('POST', ApiConfig.analyzeEndpoint, e.toString());
      AppLogger.info('Falling back to mock disease data', tag: 'ApiService');
      return _getMockResult(imagePath);
    }
    
    return null;
  }

  Future<ScanResult?> analyzeAreaScan(List<String> imagePaths) async {
    if (!_isOnline) {
      AppLogger.info('Offline mode: Using mock disease data for area scan', tag: 'ApiService');
      return _getMockAreaResult(imagePaths);
    }

    try {
      AppLogger.apiRequest('POST', ApiConfig.analyzeAreaEndpoint, data: {'fileCount': imagePaths.length});
      
      final formData = FormData.fromMap({
        'files': [
          for (var path in imagePaths)
            await MultipartFile.fromFile(path),
        ],
      });

      final response = await _dio.post(ApiConfig.analyzeAreaEndpoint, data: formData);
      
      if (response.statusCode == 200) {
        AppLogger.apiResponse('POST', ApiConfig.analyzeAreaEndpoint, response.statusCode ?? 0, data: response.data);
        return ScanResult.fromJson(response.data);
      } else {
        AppLogger.apiError('POST', ApiConfig.analyzeAreaEndpoint, 'Unexpected status code', statusCode: response.statusCode);
      }
    } catch (e) {
      AppLogger.apiError('POST', ApiConfig.analyzeAreaEndpoint, e.toString());
      AppLogger.info('Falling back to mock disease data for area scan', tag: 'ApiService');
      return _getMockAreaResult(imagePaths);
    }
    
    return null;
  }

  ScanResult _getMockResult(String imagePath) {
    final disease = MockDiseaseData.getRandomDisease();
    return ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      timestamp: DateTime.now(),
      diseaseName: disease.name,
      confidence: disease.confidence,
      severity: disease.severity,
      treatment: disease.treatment,
      urgency: disease.urgency,
      description: disease.description,
      isAreaScan: false,
    );
  }

  ScanResult _getMockAreaResult(List<String> imagePaths) {
    final disease = MockDiseaseData.getRandomDisease();
    return ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePaths.first,
      timestamp: DateTime.now(),
      diseaseName: disease.name,
      confidence: disease.confidence,
      severity: disease.severity,
      treatment: disease.treatment,
      urgency: disease.urgency,
      description: disease.description,
      isAreaScan: true,
      areaScanImages: imagePaths,
    );
  }
}
