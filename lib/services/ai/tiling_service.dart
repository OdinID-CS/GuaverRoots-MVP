import 'dart:io';
import 'package:image/image.dart' as img;
import 'inference_service.dart';
import 'image_preprocessor.dart';
import '../../core/logging/app_logger.dart';

class HeatmapPoint {
  final double x;
  final double y;
  final double severityScore;
  final double confidence;
  final String disease;

  HeatmapPoint({
    required this.x,
    required this.y,
    required this.severityScore,
    required this.confidence,
    required this.disease,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'severityScore': severityScore,
    'confidence': confidence,
    'disease': disease,
  };

  factory HeatmapPoint.fromJson(Map<String, dynamic> json) => HeatmapPoint(
    x: json['x'],
    y: json['y'],
    severityScore: json['severityScore'],
    confidence: json['confidence'],
    disease: json['disease'],
  );
}

class TilingService {
  final InferenceService _inferenceService;

  TilingService(this._inferenceService);

  Future<List<HeatmapPoint>> analyzeArea(String imagePath) async {
    AppLogger.info('Starting tiling analysis for $imagePath');

    final bytes = await File(imagePath).readAsBytes();
    final originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      throw Exception("Failed to decode image for tiling");
    }

    const int tileSize = 224;
    const double overlap = 0.5;
    final int stride = (tileSize * (1 - overlap)).toInt();

    final List<HeatmapPoint> points = [];

    int tileCount = 0;
    int cropCount = 0;

    for (int y = 0; y <= originalImage.height - tileSize; y += stride) {
      for (int x = 0; x <= originalImage.width - tileSize; x += stride) {
        tileCount++;

        try {
          final input = ImagePreprocessor.preprocessTile(originalImage, x, y, tileSize, tileSize);

          // We can't use _inferenceService.analyzeImage directly because it takes a path.
          // I'll add a method to InferenceService to accept preprocessed input.
          // Actually, let's just implement the inference logic here or refactor InferenceService.

          final prediction = await _inferenceService.analyzePreprocessed(input);

          if (prediction != null) {
            cropCount++;
            final score = _mapSeverityToScore(prediction.severity);
            points.add(HeatmapPoint(
              x: x / originalImage.width,
              y: y / originalImage.height,
              severityScore: score,
              confidence: prediction.confidence,
              disease: prediction.disease,
            ));
          }
        } catch (e) {
          // Skip tiles with low confidence or background
          continue;
        }
      }
    }

    AppLogger.info('Tiling finished. Processed $tileCount tiles, found $cropCount crop regions.');

    if (cropCount == 0) {
      throw Exception("No supported crop detected. Please capture a clearer image containing visible crop leaves.");
    }

    return points;
  }

  double _mapSeverityToScore(String severity) {
    switch (severity.toLowerCase()) {
      case 'none': return 0.0;
      case 'low': return 0.25;
      case 'moderate': return 0.5;
      case 'high': return 0.75;
      case 'severe': return 1.0;
      default: return 0.0;
    }
  }
}
