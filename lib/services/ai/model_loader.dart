import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import '../../core/logging/app_logger.dart';

class ModelLoader {
  static const String _modelPath = 'assets/models/crop_disease_model.tflite';
  static const String _labelsPath = 'assets/labels/labels.txt';

  static Future<Interpreter?> loadInterpreter({bool useGpu = false}) async {
    try {
      final interpreterOptions = InterpreterOptions();

      if (useGpu) {
        try {
          final gpuDelegate = GpuDelegateV2();
          interpreterOptions.addDelegate(gpuDelegate);
          AppLogger.info('Using GPU delegate for TFLite inference');
        } catch (e) {
          AppLogger.warning('GPU delegate not available, falling back to CPU', tag: 'ModelLoader', error: e);
        }
      }

      final interpreter = await Interpreter.fromAsset(_modelPath, options: interpreterOptions);
      AppLogger.info('TFLite Model loaded successfully from $_modelPath');
      return interpreter;
    } catch (e) {
      AppLogger.error('Failed to load TFLite model', error: e);
      return null;
    }
  }

  static Future<List<String>> loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString(_labelsPath);
      final labels = labelsData.split('\n').where((s) => s.trim().isNotEmpty).toList();
      AppLogger.info('Loaded ${labels.length} labels from $_labelsPath');
      return labels;
    } catch (e) {
      AppLogger.error('Failed to load labels', error: e);
      return [];
    }
  }
}
