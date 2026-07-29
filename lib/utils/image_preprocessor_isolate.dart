import 'dart:isolate';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImagePreprocessorIsolate {
  static Future<Float32List> preprocess(String imagePath) async {
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();

    await Isolate.spawn(
      _preprocessEntry,
      _PreprocessRequest(imagePath: imagePath, sendPort: receivePort.sendPort),
      onError: errorPort.sendPort,
      onExit: errorPort.sendPort,
    );

    final result = await receivePort.first.timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception("Image preprocessing timed out"),
    );

    receivePort.close();
    errorPort.close();

    if (result is Float32List) return result;
    throw Exception("Image preprocessing failed: $result");
  }

  static Future<img.Image?> decodeImage(String imagePath) async {
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();

    await Isolate.spawn(
      _decodeEntry,
      _DecodeRequest(imagePath: imagePath, sendPort: receivePort.sendPort),
      onError: errorPort.sendPort,
      onExit: errorPort.sendPort,
    );

    final result = await receivePort.first.timeout(
      const Duration(seconds: 15),
      onTimeout: () => null,
    );

    receivePort.close();
    errorPort.close();

    if (result is img.Image) return result;
    return null;
  }

  static void _preprocessEntry(_PreprocessRequest request) {
    try {
      final bytes = File(request.imagePath).readAsBytesSync();
      var image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception("Failed to decode image in isolate");
      }

      // Fix orientation before resizing (handles photos taken in portrait/rotated)
      image = img.bakeOrientation(image);

      final resizedImage = img.copyResize(
        image,
        width: 224,
        height: 224,
        interpolation: img.Interpolation.linear,
      );

      final input = Float32List(1 * 224 * 224 * 3);
      var bufferIndex = 0;
      for (var y = 0; y < 224; y++) {
        for (var x = 0; x < 224; x++) {
          final pixel = resizedImage.getPixel(x, y);
          input[bufferIndex++] = pixel.r / 255.0;
          input[bufferIndex++] = pixel.g / 255.0;
          input[bufferIndex++] = pixel.b / 255.0;
        }
      }

      request.sendPort.send(input);
    } catch (e) {
      request.sendPort.send(e);
    }
  }

  static void _decodeEntry(_DecodeRequest request) {
    try {
      final bytes = File(request.imagePath).readAsBytesSync();
      var image = img.decodeImage(bytes);
      if (image == null) {
        request.sendPort.send(null);
        return;
      }
      image = img.bakeOrientation(image);
      request.sendPort.send(image);
    } catch (e) {
      request.sendPort.send(null);
    }
  }
}

class _PreprocessRequest {
  final String imagePath;
  final SendPort sendPort;

  _PreprocessRequest({required this.imagePath, required this.sendPort});
}

class _DecodeRequest {
  final String imagePath;
  final SendPort sendPort;

  _DecodeRequest({required this.imagePath, required this.sendPort});
}