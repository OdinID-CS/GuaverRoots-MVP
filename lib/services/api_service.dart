import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../config/api_config.dart';
import '../core/constants/app_constants.dart';
import '../core/logging/app_logger.dart';
import '../models/scan_result.dart';
import '../models/prediction.dart';

import 'ai/inference_service.dart';
import 'ai/tiling_service.dart';

class ApiService extends ChangeNotifier {
  final Dio _dio = Dio();
  bool _isOnline = true;
  late final InferenceService _aiService;
  late final TilingService _tilingService;

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
  void _initAIService() {
    _aiService = InferenceService();
    _tilingService = TilingService(_aiService);
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

  Future<ScanResult?> analyzeImage(String imagePath, {String? location}) async {
    // Try AI inference first (works offline)
    if (_aiService.isReady) {
      try {
        final prediction = await _aiService.analyzeImage(imagePath);
        if (prediction != null) {
          AppLogger.info('AI prediction successful: ${prediction.toString()}', tag: 'ApiService');
          return _convertPredictionToScanResult(prediction, imagePath, false, location: location);
        }
      } catch (e) {
        AppLogger.error('AI inference failed', error: e, tag: 'ApiService');
        // If it's a specific error like "No crop detected", rethrow it to show to user
        if (e.toString().contains("No supported crop detected") || e.toString().contains("Low confidence")) {
          rethrow;
        }
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
          final result = ScanResult.fromJson(response.data);
          return result.copyWith(location: location);
        }
      } catch (e) {
        AppLogger.apiError('POST', ApiConfig.analyzeEndpoint, e.toString());
      }
    }

    throw Exception("Analysis failed. Please check your connection or try a clearer image.");
  }

  Future<ScanResult?> analyzeAreaScan(String imagePath, {String? location}) async {
    // Try AI tiling inference first (works offline)
    if (_aiService.isReady) {
      try {
        final heatmapPoints = await _tilingService.analyzeArea(imagePath);
        
        // Aggregate statistics
        final totalPoints = heatmapPoints.length;
        final avgSeverity = heatmapPoints.map((p) => p.severityScore).reduce((a, b) => a + b) / totalPoints;
        final diseasedCount = heatmapPoints.where((p) => p.severityScore > 0).length;
        
        // Find most likely disease (excluding healthy)
        final diseases = heatmapPoints.where((p) => p.disease != 'Healthy').map((p) => p.disease).toList();
        final mostLikelyDisease = diseases.isEmpty ? 'Healthy' : _findMostFrequent(diseases);

        final avgConfidence = heatmapPoints.map((p) => p.confidence).reduce((a, b) => a + b) / totalPoints;

        return ScanResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          imagePath: imagePath,
          timestamp: DateTime.now(),
          isAreaScan: true,
          heatmapPoints: heatmapPoints.map((p) => p.toJson()).toList(),
          diseaseName: mostLikelyDisease,
          confidence: avgConfidence,
          severity: _mapScoreToSeverity(avgSeverity),
          totalSections: totalPoints,
          healthySections: totalPoints - diseasedCount,
          diseasedSections: diseasedCount,
          overallSummary: "Area scan completed. Infected area: ${((diseasedCount / totalPoints) * 100).toStringAsFixed(1)}%.",
          recommendation: _generateRecommendation(mostLikelyDisease, avgSeverity),
          location: location,
        );
      } catch (e) {
        AppLogger.error('Area scan tiling failed', error: e, tag: 'ApiService');
        rethrow;
      }
    }

    throw Exception("Area analysis requires offline AI to be initialized.");
  }

  String _findMostFrequent(List<String> list) {
    if (list.isEmpty) return 'Unknown';
    final map = <String, int>{};
    for (final x in list) {
      map[x] = (map[x] ?? 0) + 1;
    }
    return map.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String _mapScoreToSeverity(double score) {
    if (score <= 0.0) return 'None';
    if (score <= 0.25) return 'Low';
    if (score <= 0.5) return 'Moderate';
    if (score <= 0.75) return 'High';
    return 'Severe';
  }

  String _generateRecommendation(String disease, double severity) {
    if (disease == 'Healthy') return "No treatment needed. Continue regular monitoring.";
    return "Treat for $disease. Focus on areas marked yellow and red on the heatmap.";
  }

  /// Convert AI Prediction to ScanResult for single scan
  ScanResult _convertPredictionToScanResult(Prediction prediction, String imagePath, bool isAreaScan, {String? location}) {
    return ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      timestamp: DateTime.now(),
      diseaseName: prediction.disease,
      confidence: prediction.confidence,
      severity: prediction.severity,
      isAreaScan: isAreaScan,
      notes: 'Crop: ${prediction.crop}',
      location: location,
    );
  }
}
