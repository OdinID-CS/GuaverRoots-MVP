import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/scan_result.dart';

class ApiService extends ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8000'; // FastAPI backend URL
  bool _isOnline = true;

  ApiService() {
    _initConnectivity();
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  bool get isOnline => _isOnline;

  Future<void> _initConnectivity() async {
    final connectivity = Connectivity();
    connectivity.onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
    });
  }

  Future<ScanResult?> analyzeImage(String imagePath) async {
    if (!_isOnline) {
      // Return mock result for offline demo
      return _getMockResult(imagePath);
    }

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dio.post('/analyze', data: formData);
      
      if (response.statusCode == 200) {
        return ScanResult.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('API Error: $e');
      // Fallback to mock result
      return _getMockResult(imagePath);
    }
    
    return null;
  }

  Future<ScanResult?> analyzeAreaScan(List<String> imagePaths) async {
    if (!_isOnline) {
      return _getMockAreaResult(imagePaths);
    }

    try {
      final formData = FormData.fromMap({
        'files': [
          for (var path in imagePaths)
            await MultipartFile.fromFile(path),
        ],
      });

      final response = await _dio.post('/analyze-area', data: formData);
      
      if (response.statusCode == 200) {
        return ScanResult.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('API Error: $e');
      return _getMockAreaResult(imagePaths);
    }
    
    return null;
  }

  ScanResult _getMockResult(String imagePath) {
    return ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      timestamp: DateTime.now(),
      diseaseName: 'Leaf Rust',
      confidence: 0.87,
      severity: 'Moderate',
      treatment: 'Apply fungicide spray. Remove affected leaves. Ensure proper spacing between plants.',
      urgency: 'Treat within 3-5 days',
      isAreaScan: false,
    );
  }

  ScanResult _getMockAreaResult(List<String> imagePaths) {
    return ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePaths.first,
      timestamp: DateTime.now(),
      diseaseName: 'Mixed Infection',
      confidence: 0.75,
      severity: 'High',
      treatment: 'Apply broad-spectrum fungicide. Monitor affected area weekly. Consider crop rotation.',
      urgency: 'Treat immediately',
      isAreaScan: true,
      areaScanImages: imagePaths,
    );
  }
}
