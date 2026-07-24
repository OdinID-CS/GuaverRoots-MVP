library mock_inference_service;

import '../models/prediction.dart';
import 'ai_inference_service.dart';
import '../../core/logging/app_logger.dart';
import '../../data/mock_disease_data.dart';

/// Mock implementation of AI inference service for demo/testing
/// 
/// This service returns realistic mock predictions without using actual AI.
/// It implements the same interface as real AI services, allowing seamless
/// replacement when a real model is available.
class MockInferenceService implements AIInferenceService {
  bool _isInitialized = false;

  @override
  Future<bool> initialize() async {
    // Mock initialization - always succeeds
    _isInitialized = true;
    AppLogger.info('MockInferenceService initialized', tag: 'MockAI');
    return true;
  }

  @override
  Future<Prediction?> analyzeImage(String imagePath) async {
    if (!_isInitialized) {
      AppLogger.warning('MockInferenceService not initialized', tag: 'MockAI');
      return null;
    }

    try {
      // Get a random disease sample from mock data
      final diseaseSample = MockDiseaseData.getRandomDisease();
      
      // Map mock data to Prediction model
      final prediction = Prediction(
        crop: _getRandomCrop(),
        disease: diseaseSample.name,
        confidence: diseaseSample.confidence,
        severity: diseaseSample.severity,
        recommendationId: _generateRecommendationId(diseaseSample.name),
      );

      AppLogger.info('Mock prediction generated: ${prediction.toString()}', tag: 'MockAI');
      return prediction;
    } catch (e) {
      AppLogger.error('Mock inference failed', error: e, tag: 'MockAI');
      return null;
    }
  }

  @override
  Future<AreaPrediction?> analyzeArea(List<String> imagePaths) async {
    if (!_isInitialized) {
      AppLogger.warning('MockInferenceService not initialized', tag: 'MockAI');
      return null;
    }

    if (imagePaths.isEmpty) {
      AppLogger.warning('No images provided for area analysis', tag: 'MockAI');
      return null;
    }

    try {
      // Generate a prediction for each image
      final predictions = <Prediction>[];
      for (int i = 0; i < imagePaths.length; i++) {
        final diseaseSample = MockDiseaseData.getAreaScanResults(imagePaths.length)[i];
        final prediction = Prediction(
          crop: _getRandomCrop(),
          disease: diseaseSample.name,
          confidence: diseaseSample.confidence,
          severity: diseaseSample.severity,
          recommendationId: _generateRecommendationId(diseaseSample.name),
        );
        predictions.add(prediction);
      }

      // Create area prediction from individual predictions
      final areaPrediction = AreaPrediction.fromPredictions(predictions);
      
      AppLogger.info('Mock area prediction generated: ${areaPrediction.toString()}', tag: 'MockAI');
      return areaPrediction;
    } catch (e) {
      AppLogger.error('Mock area inference failed', error: e, tag: 'MockAI');
      return null;
    }
  }

  @override
  bool get isReady => _isInitialized;

  @override
  String get serviceName => 'MockInferenceService';

  @override
  Future<void> dispose() async {
    _isInitialized = false;
    AppLogger.info('MockInferenceService disposed', tag: 'MockAI');
  }

  // Helper methods

  String _getRandomCrop() {
    final crops = ['tomato', 'maize', 'cassava', 'potato', 'bean'];
    return crops[(DateTime.now().millisecondsSinceEpoch) % crops.length];
  }

  String _generateRecommendationId(String diseaseName) {
    // Generate a consistent ID based on disease name
    return 'rec_${diseaseName.toLowerCase().replaceAll(' ', '_')}';
  }
}
