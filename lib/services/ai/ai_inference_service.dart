library ai_inference_service;

import 'package:guaverroots/models/prediction.dart';

/// Abstract interface for AI disease inference
/// 
/// Implementations can include:
/// - MockInferenceService: For demo/testing without real AI
/// - TFLiteInferenceService: For on-device TensorFlow Lite inference
/// - APIInferenceService: For cloud-based AI inference
abstract class AIInferenceService {
  /// Initialize the inference service
  /// 
  /// Returns true if initialization successful, false otherwise
  Future<bool> initialize();
  
  /// Analyze a single image for disease detection
  /// 
  /// [imagePath] - Path to the image file to analyze
  /// 
  /// Returns a Prediction with crop, disease, confidence, severity
  /// Returns null if analysis fails
  Future<Prediction?> analyzeImage(String imagePath);
  
  /// Analyze multiple images for area-level disease detection
  /// 
  /// [imagePaths] - List of paths to image files to analyze
  /// 
  /// Returns an AreaPrediction with individual predictions and overall health
  /// Returns null if analysis fails
  Future<AreaPrediction?> analyzeArea(List<String> imagePaths);
  
  /// Check if the service is ready for inference
  bool get isReady;
  
  /// Get the service name for logging
  String get serviceName;
  
  /// Clean up resources
  Future<void> dispose();
}
