import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';
import '../services/ai/tiling_service.dart';
import '../models/scan_result.dart';
import '../core/exceptions/app_exceptions.dart';
import '../core/constants/app_constants.dart';
import '../utils/image_compressor.dart';
import '../core/logging/app_logger.dart';
import '../utils/device_performance.dart';
import 'heatmap_screen.dart';

class AreaScanScreen extends StatefulWidget {
  const AreaScanScreen({super.key});

  @override
  State<AreaScanScreen> createState() => _AreaScanScreenState();
}

class _AreaScanScreenState extends State<AreaScanScreen> {
  final List<String> _capturedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  late final int _maxAreaPhotos = DevicePerformance.detect().maxAreaPhotos;

  Future<void> _capturePhoto() async {
    try {
      await PermissionService.requestCamera();
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null && _capturedImages.length < _maxAreaPhotos) {
        setState(() {
          _capturedImages.add(image.path);
        });
        AppLogger.camera('Photo captured for area scan', success: true, details: image.path);
        final compressedPath = await ImageCompressor.compressImage(image.path);
        setState(() {
          _capturedImages.add(compressedPath);
        });
      }
    } on PermissionException catch (e) {
      AppLogger.permission('Area scan camera blocked', false);
      AppLogger.error('Area scan camera blocked', error: e, tag: 'AreaScanScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      AppLogger.camera('Photo capture for area scan', success: false, details: e.toString());
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      await PermissionService.requestStorage();
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && _capturedImages.length < _maxAreaPhotos) {
        setState(() {
          _capturedImages.add(image.path);
        });
        AppLogger.camera('Image selected from gallery for area scan', success: true, details: image.path);
        final compressedPath = await ImageCompressor.compressImage(image.path);
        setState(() {
          _capturedImages.add(compressedPath);
        });
      }
    } on PermissionException catch (e) {
      AppLogger.permission('Area scan storage blocked', false);
      AppLogger.error('Area scan storage blocked', error: e, tag: 'AreaScanScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      AppLogger.camera('Gallery selection for area scan', success: false, details: e.toString());
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
  }

  Future<String?> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      
      return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    } catch (e) {
      AppLogger.warning('Unable to get current location', tag: 'AreaScanScreen', error: e.toString());
      return null;
    }
  }

  Future<void> _analyzeArea() async {
    if (_capturedImages.isEmpty) return;

    setState(() => _isAnalyzing = true);
    AppLogger.info('Starting multi-photo area scan analysis');

    try {
      final location = await _getCurrentLocation();
      final apiService = Provider.of<ApiService>(context, listen: false);

      final List<HeatmapPoint> combinedPoints = [];
      int totalPoints = 0;
      int diseasedCount = 0;
      final List<String> diseases = [];
      double totalConfidence = 0;
      int analyzedCount = 0;

      for (final imagePath in _capturedImages) {
        try {
          final result = await apiService.analyzeAreaScan(imagePath, location: location);
          if (result != null) {
            if (result.heatmapPoints != null) {
              combinedPoints.addAll(
                result.heatmapPoints!.map((p) => HeatmapPoint.fromJson(p)),
              );
            }
            totalPoints += result.totalSections ?? 0;
            diseasedCount += result.diseasedSections ?? 0;
            if (result.diseaseName != null && result.diseaseName != 'Healthy') {
              diseases.add(result.diseaseName!);
            }
            totalConfidence += result.confidence ?? 0;
            analyzedCount++;
          }
        } catch (e) {
          AppLogger.warning('Area scan photo failed', tag: 'AreaScanScreen', error: e.toString());
        }
      }

      if (combinedPoints.isEmpty) {
        throw Exception("No supported crop detected in any photo. Please capture clearer images containing visible crop leaves.");
      }

      final avgConfidence = analyzedCount > 0 ? totalConfidence / analyzedCount : 0.0;
      final mostLikelyDisease = diseases.isEmpty ? 'Healthy' : _findMostFrequent(diseases);

      final finalResult = ScanResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: _capturedImages.first,
        timestamp: DateTime.now(),
        isAreaScan: true,
        areaScanImages: List.from(_capturedImages),
        heatmapPoints: combinedPoints.map((p) => p.toJson()).toList(),
        diseaseName: mostLikelyDisease,
        confidence: avgConfidence,
        severity: _mapScoreToSeverity(combinedPoints.map((p) => p.severityScore).reduce((a, b) => a + b) / combinedPoints.length),
        totalSections: totalPoints,
        healthySections: totalPoints - diseasedCount,
        diseasedSections: diseasedCount,
        overallSummary: "Area scan completed across ${_capturedImages.length} images. Infected area: ${totalPoints > 0 ? ((diseasedCount / totalPoints) * 100).toStringAsFixed(1) : '0.0'}%.",
        recommendation: _generateRecommendation(mostLikelyDisease, combinedPoints.map((p) => p.severityScore).reduce((a, b) => a + b) / combinedPoints.length),
        location: location,
      );

      await StorageService.saveScanResult(finalResult);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HeatmapScreen(scanResult: finalResult),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Area scan analysis failed', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  String _findMostFrequent(List<String> list) {
    final map = <String, int>{};
    for (final item in list) {
      map[item] = (map[item] ?? 0) + 1;
    }
    return map.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String _mapScoreToSeverity(double score) {
    if (score < 0.15) return 'None';
    if (score < 0.4) return 'Low';
    if (score < 0.7) return 'Moderate';
    return 'High';
  }

  String _generateRecommendation(String disease, double severityScore) {
    if (disease == 'Healthy') {
      return 'Crops appear healthy. Continue regular monitoring and maintenance.';
    }
    if (severityScore > 0.7) {
      return 'Immediate action required. Apply appropriate fungicide or treatment. Consult an agricultural expert if the infection spreads rapidly.';
    } else if (severityScore > 0.4) {
      return 'Monitor closely and apply recommended treatment. Consider removing affected leaves to prevent spread.';
    }
    return 'Early stage detected. Apply preventive measures and monitor closely over the next few days.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Area Scan'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isAnalyzing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(height: 20),
                  const Text(
                    'Generating Heatmap...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analyzing ${_capturedImages.length} images...',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: _capturedImages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 100,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Capture up to 9 crop area photos',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'Take multiple photos of your field. A disease intensity heatmap will be generated from all images.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _capturedImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(_capturedImages[index]),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: IconButton(
                                      onPressed: () => _removePhoto(index),
                                      icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(UIConstants.paddingLarge),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_capturedImages.isEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showPhotoOptions,
                            icon: const Icon(Icons.add_a_photo),
                            label: const Text('Add Crop Photos'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        )
                      else ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _capturedImages.length < _maxAreaPhotos ? _showPhotoOptions : null,
                                icon: const Icon(Icons.add_photo_alternate),
                                label: Text(_capturedImages.length < _maxAreaPhotos ? 'Add More' : 'Max $_maxAreaPhotos Photos'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  side: const BorderSide(color: Colors.green),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _analyzeArea,
                                icon: const Icon(Icons.analytics),
                                label: Text('Analyze ${_capturedImages.length} Photos'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _capturePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }
}
