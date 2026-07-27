import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math' as math;
import '../../models/prediction.dart';
import '../../core/logging/app_logger.dart';
import 'ai_inference_service.dart';
import 'model_loader.dart';
import 'image_preprocessor.dart';
import 'prediction_parser.dart';

class InferenceService implements AIInferenceService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  @override
  Future<bool> initialize() async {
    _interpreter = await ModelLoader.loadInterpreter();
    _labels = await ModelLoader.loadLabels();

    if (_interpreter != null && _labels.isNotEmpty) {
      _isInitialized = true;
      AppLogger.info('InferenceService initialized with ${_labels.length} labels');
      return true;
    }

    _isInitialized = false;
    AppLogger.error('InferenceService failed to initialize');
    return false;
  }

  @override
  Future<Prediction?> analyzeImage(String imagePath) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return null;
    }

    try {
      final input = ImagePreprocessor.preprocess(imagePath);
      final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

      _interpreter!.run(input, output);

      final results = output[0] as List<double>;
      final maxConfidence = results.reduce(math.max);
      final maxIndex = results.indexOf(maxConfidence);
      final rawLabel = _labels[maxIndex];

      AppLogger.info('Raw prediction: $rawLabel with confidence $maxConfidence');

      // 60% Confidence threshold
      if (maxConfidence < 0.6) {
        throw Exception("Low confidence prediction ($maxConfidence)");
      }

      final parsed = PredictionParser.parse(rawLabel);

      if (parsed['disease'] == 'Background') {
        throw Exception("No supported crop detected in the image.");
      }

      return Prediction(
        crop: parsed['crop'],
        disease: parsed['disease'],
        confidence: maxConfidence,
        severity: PredictionParser.mapToSeverity(maxConfidence, parsed['isHealthy']),
      );
    } catch (e) {
      AppLogger.error('Inference failed', error: e);
      rethrow;
    }
  }

  /// New method for tiling support
  Future<Prediction?> analyzePreprocessed(dynamic input) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return null;
    }

    try {
      final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
      _interpreter!.run(input, output);

      final results = output[0] as List<double>;
      final maxConfidence = results.reduce(math.max);
      final maxIndex = results.indexOf(maxConfidence);
      final rawLabel = _labels[maxIndex];

      if (maxConfidence < 0.6) return null;

      final parsed = PredictionParser.parse(rawLabel);
      if (parsed['disease'] == 'Background') return null;

      return Prediction(
        crop: parsed['crop'],
        disease: parsed['disease'],
        confidence: maxConfidence,
        severity: PredictionParser.mapToSeverity(maxConfidence, parsed['isHealthy']),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<AreaPrediction?> analyzeArea(List<String> imagePaths) async {
    // This is the legacy area scan method.
    // In the new architecture, AreaScanScreen will call TilingService.
    // For compatibility with the interface, we can keep it or return null.
    return null;
  }

  @override
  bool get isReady => _isInitialized;

  @override
  String get serviceName => 'TFLiteInferenceService';

  @override
  Future<void> dispose() async {
    _interpreter?.close();
    _isInitialized = false;
  }
}
