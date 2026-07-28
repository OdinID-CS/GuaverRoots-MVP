import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import '../../models/prediction.dart';
import '../../core/logging/app_logger.dart';
import 'ai_inference_service.dart';
import 'model_loader.dart';
import '../../utils/image_preprocessor_isolate.dart';
import 'prediction_parser.dart';

class InferenceService implements AIInferenceService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  @override
  Future<bool> initialize() async {
    final interpreter = await ModelLoader.loadInterpreter();
    _labels = await ModelLoader.loadLabels();

    if (interpreter != null && _labels.isNotEmpty) {
      _interpreter = interpreter;
      await _warmUp();
      _isInitialized = true;
      AppLogger.info('InferenceService initialized with ${_labels.length} labels');
      return true;
    }

    _interpreter = null;
    _isInitialized = false;
    AppLogger.error('InferenceService failed to initialize');
    return false;
  }

  Future<void> _warmUp() async {
    try {
      final dummyInput = Float32List(224 * 224 * 3);
      final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
      _interpreter!.run(dummyInput, output);
      AppLogger.info('Interpreter warmed up successfully');
    } catch (e) {
      AppLogger.warning('Interpreter warm-up failed', tag: 'InferenceService', error: e);
    }
  }

  @override
  Future<Prediction?> analyzeImage(String imagePath) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return null;
    }

    try {
      final input = await ImagePreprocessorIsolate.preprocess(imagePath);
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
    _interpreter = null;
    _isInitialized = false;
  }
}
