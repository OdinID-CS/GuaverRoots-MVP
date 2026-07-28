import 'dart:isolate';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImagePreprocessorIsolate {
  static Future<Float32List> preprocess(String imagePath) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _preprocessEntry,
      _PreprocessRequest(imagePath, receivePort.sendPort),
    );

    final result = await receivePort.first as Float32List;
    return result;
  }

  static void _preprocessEntry(_PreprocessRequest request) {
    try {
      final bytes = File(request.imagePath).readAsBytesSync();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception("Failed to decode image in isolate");
      }

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
}

class _PreprocessRequest {
  final String imagePath;
  final SendPort sendPort;

  _PreprocessRequest(this.imagePath, this.sendPort);
}
