import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../core/constants/app_constants.dart';
import '../core/logging/app_logger.dart';
import '../utils/image_compressor.dart';
import 'treatment_screen.dart';
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

  Future<void> _capturePhoto() async {
    if (_capturedImages.length >= AppConstants.maxAreaPhotos) return;

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _capturedImages.add(image.path);
        });
        AppLogger.camera('Photo captured for area scan', success: true, details: 'Total: ${_capturedImages.length}');
      }
    } catch (e) {
      AppLogger.camera('Photo capture for area scan', success: false, details: e.toString());
    }
  }

  Future<void> _pickFromGallery() async {
    if (_capturedImages.length >= AppConstants.maxAreaPhotos) return;

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _capturedImages.add(image.path);
        });
        AppLogger.camera('Image selected from gallery for area scan', success: true, details: 'Total: ${_capturedImages.length}');
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

  Future<void> _analyzeArea() async {
    if (_capturedImages.isEmpty) return;

    setState(() => _isAnalyzing = true);
    AppLogger.info('Starting area scan analysis with ${_capturedImages.length} images');

    try {
      // Compress all images before analysis
      final compressedImages = await ImageCompressor.compressImages(_capturedImages);
      AppLogger.info('Compressed ${compressedImages.length} images for area scan');
      
      if (!mounted) return;
      
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.analyzeAreaScan(compressedImages);

      if (result != null && mounted) {
        await StorageService.saveScanResult(result);
        
        if (mounted) {
          // Navigate to HeatmapScreen if area scan results are available, otherwise TreatmentScreen
          if (result.areaScanResults != null && result.areaScanResults!.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HeatmapScreen(scanResult: result),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TreatmentScreen(scanResult: result),
              ),
            );
          }
        }
      } else if (mounted) {
        AppLogger.warning('Area scan analysis returned null result');
      }
    } catch (e) {
      AppLogger.error('Area scan analysis failed', error: e);
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Area Scan'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_capturedImages.isNotEmpty)
            TextButton.icon(
              onPressed: _analyzeArea,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Analyze',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
        ],
      ),
      body: _isAnalyzing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 20),
                  Text(
                    'Analyzing area...',
                    style: TextStyle(fontSize: 18),
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
                                Icons.grid_on,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Take photos of your farm area',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to add photos (max ${AppConstants.maxAreaPhotos})',
                                style: TextStyle(
                                  fontSize: UIConstants.fontSizeMedium,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(UIConstants.paddingMedium),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: UIConstants.gridCrossAxisCount,
                            crossAxisSpacing: UIConstants.gridCrossAxisSpacing,
                            mainAxisSpacing: UIConstants.gridMainAxisSpacing,
                          ),
                          itemCount: _capturedImages.length +
                              (_capturedImages.length < AppConstants.maxAreaPhotos ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _capturedImages.length) {
                              return GestureDetector(
                                onTap: _capturedImages.length < AppConstants.maxAreaPhotos
                                    ? _showPhotoOptions
                                    : null,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                                    border: Border.all(
                                      color: Colors.grey[400]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    size: UIConstants.iconLarge,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            }

                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                                  child: Image.file(
                                    File(_capturedImages[index]),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removePhoto(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(UIConstants.paddingSmall),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: UIConstants.iconSmall,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: UIConstants.paddingSmall, vertical: UIConstants.paddingSmall),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: UIConstants.fontSizeSmall,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(UIConstants.paddingMedium),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _capturedImages.length < AppConstants.maxAreaPhotos
                            ? _showPhotoOptions
                            : null,
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Add Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(UIConstants.buttonMinWidth, UIConstants.buttonHeight),
                          textStyle: const TextStyle(fontSize: UIConstants.fontSizeLarge),
                        ),
                      ),
                      if (_capturedImages.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _analyzeArea,
                          icon: const Icon(Icons.analytics),
                          label: const Text('Analyze'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(UIConstants.buttonMinWidth, UIConstants.buttonHeight),
                            textStyle: const TextStyle(fontSize: UIConstants.fontSizeLarge),
                          ),
                        ),
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
