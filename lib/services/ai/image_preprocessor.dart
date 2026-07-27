import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImagePreprocessor {
  static const int inputSize = 224;

  static Float32List preprocess(String imagePath) {
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
    return input;
  }

  /// Extracts a tile from an image and preproccesses it
  static Float32List preprocessTile(img.Image originalImage, int x, int y, int width, int height) {
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
    return input;
  }
}
