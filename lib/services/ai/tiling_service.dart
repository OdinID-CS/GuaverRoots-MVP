import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'inference_service.dart';
import 'image_preprocessor.dart';
import '../../core/logging/app_logger.dart';
import '../../utils/device_performance.dart';

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

  Future<List<HeatmapPoint>> analyzeArea(String imagePath, {PerformanceMode? mode}) async {
    final performanceMode = mode ?? DevicePerformance.detect();
    AppLogger.info('Starting tiling analysis for $imagePath in ${performanceMode.name} mode');

    final bytes = await File(imagePath).readAsBytes();
    final originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      throw Exception("Failed to decode image for tiling");
    }

    const int tileSize = 224;
    final double overlap = performanceMode.tileOverlap;
    final int stride = (tileSize * (1 - overlap)).toInt();
    final int batchSize = performanceMode.tileBatchSize;

    final List<HeatmapPoint> points = [];

    final List<_TileInput> tiles = [];

    for (int y = 0; y <= originalImage.height - tileSize; y += stride) {
      for (int x = 0; x <= originalImage.width - tileSize; x += stride) {
        tiles.add(_TileInput(x: x, y: y));
      }
    }

    int tileCount = tiles.length;
    int cropCount = 0;

    for (int i = 0; i < tiles.length; i += batchSize) {
      final end = (i + batchSize > tiles.length) ? tiles.length : i + batchSize;
      final batch = tiles.sublist(i, end);

      for (final tile in batch) {
        try {
          final input = ImagePreprocessor.preprocessTile(originalImage, tile.x, tile.y, tileSize, tileSize);
          final prediction = await _inferenceService.analyzePreprocessed(input);

          if (prediction != null) {
            cropCount++;
            final score = _mapSeverityToScore(prediction.severity);
            points.add(HeatmapPoint(
              x: tile.x / originalImage.width,
              y: tile.y / originalImage.height,
              severityScore: score,
              confidence: prediction.confidence,
              disease: prediction.disease,
            ));
          }
        } catch (e) {
          continue;
        }
      }

      AppLogger.info('Tiling progress: processed $end/${tiles.length} tiles');
    }

    AppLogger.info('Tiling finished. Processed $tileCount tiles, found $cropCount crop regions in $performanceMode mode.');

    if (cropCount == 0) {
      throw Exception("No supported crop detected. Please capture a clearer image containing visible crop leaves.");
    }

    return points;
  }

  Future<Float32List> preprocessTileInput(String imagePath, int x, int y, int width, int height) async {
    final bytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) throw Exception("Failed to decode image for tiling");

    return ImagePreprocessor.preprocessTile(image, x, y, width, height);
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

class _TileInput {
  final int x;
  final int y;

  _TileInput({required this.x, required this.y});
}

