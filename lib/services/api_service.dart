import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/scan_result.dart';
import '../models/prediction.dart';
import '../config/api_config.dart';
import '../data/mock_disease_data.dart';
import '../core/logging/app_logger.dart';
import '../core/constants/app_constants.dart';
import 'ai/ai_inference_service.dart';
import 'ai/mock_inference_service.dart';

class ApiService extends ChangeNotifier {
  final Dio _dio = Dio();
  bool _isOnline = true;
  late final AIInferenceService _aiService;

  ApiService() {
    _initConnectivity();
    _initAIService();
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: AppConstants.connectionTimeoutSeconds);
    _dio.options.receiveTimeout = const Duration(seconds: AppConstants.receiveTimeoutSeconds);
    AppLogger.info('ApiService initialized', tag: 'ApiService');
  }

  bool get isOnline => _isOnline;

  /// Initialize the AI inference service
  /// Currently uses MockInferenceService, can be swapped for TFLite implementation
  void _initAIService() {
    _aiService = MockInferenceService();
    _aiService.initialize().then((success) {
      if (success) {
        AppLogger.info('AI service initialized: ${_aiService.serviceName}', tag: 'ApiService');
      } else {
        AppLogger.warning('AI service initialization failed', tag: 'ApiService');
      }
    });
  }

  Future<void> _initConnectivity() async {
    final connectivity = Connectivity();
    connectivity.onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      AppLogger.info('Connectivity changed: ${_isOnline ? "Online" : "Offline"}', tag: 'ApiService');
      notifyListeners();
    });
  }

  Future<ScanResult?> analyzeImage(String imagePath) async {
    // Try AI inference first (works offline)
    if (_aiService.isReady) {
      try {
        final prediction = await _aiService.analyzeImage(imagePath);
        if (prediction != null) {
          AppLogger.info('AI prediction successful: ${prediction.toString()}', tag: 'ApiService');
          return _convertPredictionToScanResult(prediction, imagePath, false);
        }
      } catch (e) {
        AppLogger.error('AI inference failed, falling back to API', error: e, tag: 'ApiService');
      }
    }

    // Fallback to API if online
    if (_isOnline) {
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
      }
    }

    // Final fallback to legacy mock data
    AppLogger.info('Using legacy mock disease data', tag: 'ApiService');
    return _getMockResult(imagePath);
  }

  Future<ScanResult?> analyzeAreaScan(List<String> imagePaths) async {
    // Try AI inference first (works offline)
    if (_aiService.isReady) {
      try {
        final areaPrediction = await _aiService.analyzeArea(imagePaths);
        if (areaPrediction != null) {
          AppLogger.info('AI area prediction successful: ${areaPrediction.toString()}', tag: 'ApiService');
          return _convertAreaPredictionToScanResult(areaPrediction, imagePaths);
        }
      } catch (e) {
        AppLogger.error('AI area inference failed, falling back to API', error: e, tag: 'ApiService');
      }
    }

    // Fallback to API if online
    if (_isOnline) {
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
      }
    }

    // Final fallback to legacy mock data
    AppLogger.info('Using legacy mock disease data for area scan', tag: 'ApiService');
    return _getMockAreaResult(imagePaths);
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

  /// Convert AI Prediction to ScanResult for single scan
  ScanResult _convertPredictionToScanResult(Prediction prediction, String imagePath, bool isAreaScan) {
    final disease = MockDiseaseData.getDiseaseByName(prediction.disease);
    return ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      timestamp: DateTime.now(),
      diseaseName: prediction.disease,
      confidence: prediction.confidence,
      severity: prediction.severity,
      treatment: disease?.treatment,
      urgency: disease?.urgency,
      description: disease?.description,
      isAreaScan: isAreaScan,
      notes: 'Crop: ${prediction.crop}${prediction.recommendationId != null ? ', Rec ID: ${prediction.recommendationId}' : ''}',
    );
  }

  /// Convert AI AreaPrediction to ScanResult for area scan
  ScanResult _convertAreaPredictionToScanResult(AreaPrediction areaPrediction, List<String> imagePaths) {
    // Use the most severe disease from the predictions
    final mostSeverePrediction = _getMostSeverePrediction(areaPrediction.predictions);
    final disease = MockDiseaseData.getDiseaseByName(mostSeverePrediction.disease);
    
    return ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePaths.first,
      timestamp: DateTime.now(),
      diseaseName: mostSeverePrediction.disease,
      confidence: mostSeverePrediction.confidence,
      severity: mostSeverePrediction.severity,
      treatment: disease?.treatment,
      urgency: disease?.urgency,
      description: disease?.description,
      isAreaScan: true,
      areaScanImages: imagePaths,
      notes: 'Overall Health: ${areaPrediction.overallHealth} | Healthy: ${areaPrediction.healthyPercentage.toStringAsFixed(1)}% | Monitor: ${areaPrediction.monitoringPercentage.toStringAsFixed(1)}% | Risk: ${areaPrediction.highRiskPercentage.toStringAsFixed(1)}%',
    );
  }

  /// Get the most severe prediction from a list
  Prediction _getMostSeverePrediction(List<Prediction> predictions) {
    if (predictions.isEmpty) {
      // Return a default healthy prediction if list is empty
      return Prediction(
        crop: 'unknown',
        disease: 'Healthy',
        confidence: 0.95,
        severity: 'None',
      );
    }
    
    // Sort by severity (high > moderate > low > none)
    predictions.sort((a, b) {
      final severityOrder = {'high': 0, 'moderate': 1, 'low': 2, 'none': 3};
      final aSeverity = severityOrder[a.severity.toLowerCase()] ?? 4;
      final bSeverity = severityOrder[b.severity.toLowerCase()] ?? 4;
      return aSeverity.compareTo(bSeverity);
    });
    
    return predictions.first;
  }
}
