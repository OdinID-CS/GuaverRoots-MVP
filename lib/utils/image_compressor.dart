library image_compressor;

import 'dart:io';
import 'package:image/image.dart' as img;
import '../core/exceptions/app_exceptions.dart';
import '../core/logging/app_logger.dart';

/// Utility class for image compression operations
class ImageCompressor {
  /// Maximum width for compressed images
  static const int maxWidth = 1920;
  
  /// Maximum height for compressed images
  static const int maxHeight = 1080;
  
  /// JPEG quality for compression (0-100)
  static const int jpegQuality = 85;

  /// Compress an image file and return the path to the compressed file
  /// 
  /// Returns the path to the compressed image file.
  /// If compression fails, returns the original path.
  static Future<String> compressImage(String imagePath) async {
    try {
      AppLogger.debug('Starting image compression', tag: 'ImageCompressor');
      
      final file = File(imagePath);
      if (!await file.exists()) {
        throw CompressionException('Image file does not exist: $imagePath');
      }

      // Read the image
      final originalBytes = await file.readAsBytes();
      AppLogger.debug('Original image size: ${originalBytes.length} bytes', tag: 'ImageCompressor');

      // Decode the image
      final image = img.decodeImage(originalBytes);
      if (image == null) {
        throw CompressionException('Failed to decode image: $imagePath');
      }

      // Check if compression is needed
      final needsResize = image.width > maxWidth || image.height > maxHeight;
      final needsCompression = originalBytes.length > 1024 * 1024; // > 1MB

      if (!needsResize && !needsCompression) {
        AppLogger.debug('Image does not need compression', tag: 'ImageCompressor');
        return imagePath;
      }

      // Resize if needed
      img.Image resizedImage = image;
      if (needsResize) {
        resizedImage = img.copyResize(
          image,
          width: maxWidth,
          height: maxHeight,
          maintainAspect: true,
        );
        AppLogger.debug(
          'Resized image from ${image.width}x${image.height} to ${resizedImage.width}x${resizedImage.height}',
          tag: 'ImageCompressor',
        );
      }

      // Encode with compression
      final compressedBytes = img.encodeJpg(resizedImage, quality: jpegQuality);
      AppLogger.debug('Compressed image size: ${compressedBytes.length} bytes', tag: 'ImageCompressor');

      // Calculate compression ratio
      final ratio = (compressedBytes.length / originalBytes.length * 100).toStringAsFixed(1);
      AppLogger.info('Compression ratio: $ratio%', tag: 'ImageCompressor');

      // Save compressed image
      final compressedPath = imagePath.replaceAllMapped(
        RegExp(r'\.(jpg|jpeg|png)$'),
        (match) => '_compressed.jpg',
      );
      
      await File(compressedPath).writeAsBytes(compressedBytes);
      AppLogger.camera('Image compression', success: true, details: 'Saved to $compressedPath');

      return compressedPath;
    } catch (e) {
      if (e is CompressionException) {
        AppLogger.error('Image compression failed: ${e.message}', error: e, tag: 'ImageCompressor');
        rethrow;
      }
      AppLogger.error('Unexpected error during image compression', error: e, tag: 'ImageCompressor');
      throw CompressionException('Failed to compress image: $e', originalError: e);
    }
  }

  /// Compress multiple images and return their compressed paths
  static Future<List<String>> compressImages(List<String> imagePaths) async {
    final compressedPaths = <String>[];
    
    for (final path in imagePaths) {
      try {
        final compressedPath = await compressImage(path);
        compressedPaths.add(compressedPath);
      } catch (e) {
        AppLogger.warning('Failed to compress image: $path, using original', error: e, tag: 'ImageCompressor');
        compressedPaths.add(path); // Use original if compression fails
      }
    }
    
    return compressedPaths;
  }

  /// Get image dimensions without fully loading the image
  static Future<Map<String, int>> getImageDimensions(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw CompressionException('Failed to decode image for dimensions');
      }
      
      return {'width': image.width, 'height': image.height};
    } catch (e) {
      AppLogger.error('Failed to get image dimensions', error: e, tag: 'ImageCompressor');
      throw CompressionException('Failed to get image dimensions: $e', originalError: e);
    }
  }

  /// Get file size in human-readable format
  static String getFileSize(String imagePath) {
    final file = File(imagePath);
    final bytes = file.lengthSync();
    
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
