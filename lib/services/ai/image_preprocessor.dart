import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ImagePreprocessor {
  static const int inputSize = 224;

  static List preprocess(String imagePath) {
    final bytes = File(imagePath).readAsBytesSync();
    final image = img.decodeImage(bytes);

    if (image == null) throw Exception("Failed to decode image");

    final resizedImage = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    final input = Float32List(1 * inputSize * inputSize * 3);
    var bufferIndex = 0;
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = resizedImage.getPixel(x, y);
        // Normalize 0-1
        input[bufferIndex++] = pixel.r / 255.0;
        input[bufferIndex++] = pixel.g / 255.0;
        input[bufferIndex++] = pixel.b / 255.0;
      }
    }
    return input.reshape([1, inputSize, inputSize, 3]);
  }

  /// Extracts a tile from an image and preproccesses it
  static List preprocessTile(img.Image originalImage, int x, int y, int width, int height) {
    final tile = img.copyCrop(originalImage, x: x, y: y, width: width, height: height);
    final resizedTile = img.copyResize(
      tile,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    final input = Float32List(1 * inputSize * inputSize * 3);
    var bufferIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        final pixel = resizedTile.getPixel(j, i);
        input[bufferIndex++] = pixel.r / 255.0;
        input[bufferIndex++] = pixel.g / 255.0;
        input[bufferIndex++] = pixel.b / 255.0;
      }
    }
    return input.reshape([1, inputSize, inputSize, 3]);
  }

  static bool isLikelyCropTile(img.Image tile, {double varianceThreshold = 10.0}) {
    final gray = List<double>.filled(tile.width * tile.height, 0.0);
    for (var y = 0; y < tile.height; y++) {
      for (var x = 0; x < tile.width; x++) {
        final pixel = tile.getPixel(x, y);
        gray[y * tile.width + x] = (pixel.r + pixel.g + pixel.b) / 3.0;
      }
    }

    if (gray.isEmpty) return false;

    final mean = gray.reduce((a, b) => a + b) / gray.length;
    final variance = gray.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / gray.length;

    return variance > varianceThreshold;
  }

  static bool isLikelyCropTileFromPath(String imagePath, int x, int y, int width, int height, {double varianceThreshold = 10.0}) {
    final bytes = File(imagePath).readAsBytesSync();
    final image = img.decodeImage(bytes);
    if (image == null) return true;

    final tile = img.copyCrop(image, x: x, y: y, width: width, height: height);
    return isLikelyCropTile(tile, varianceThreshold: varianceThreshold);
  }
}