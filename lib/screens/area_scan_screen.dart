import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/scan_result.dart';
import 'treatment_screen.dart';

class AreaScanScreen extends StatefulWidget {
  const AreaScanScreen({super.key});

  @override
  State<AreaScanScreen> createState() => _AreaScanScreenState();
}

class _AreaScanScreenState extends State<AreaScanScreen> {
  final List<String> _capturedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  static const int _maxPhotos = 9;

  Future<void> _capturePhoto() async {
    if (_capturedImages.length >= _maxPhotos) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _capturedImages.add(image.path);
      });
    }
  }

  Future<void> _pickFromGallery() async {
    if (_capturedImages.length >= _maxPhotos) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _capturedImages.add(image.path);
      });
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

    final apiService = Provider.of<ApiService>(context, listen: false);
    final result = await apiService.analyzeAreaScan(_capturedImages);

    if (result != null && mounted) {
      await StorageService.saveScanResult(result);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TreatmentScreen(scanResult: result),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isAnalyzing = false);
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
                                'Tap + to add photos (max $_maxPhotos)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _capturedImages.length +
                              (_capturedImages.length < _maxPhotos ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _capturedImages.length) {
                              return GestureDetector(
                                onTap: _capturedImages.length < _maxPhotos
                                    ? _showPhotoOptions
                                    : null,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[400]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    size: 40,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            }

                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
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
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
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
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _capturedImages.length < _maxPhotos
                            ? _showPhotoOptions
                            : null,
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Add Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(140, 50),
                          textStyle: const TextStyle(fontSize: 16),
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
                            minimumSize: const Size(140, 50),
                            textStyle: const TextStyle(fontSize: 16),
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
