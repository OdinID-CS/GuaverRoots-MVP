import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../core/constants/app_constants.dart';
import '../core/logging/app_logger.dart';
import '../utils/image_compressor.dart';
import 'treatment_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  bool _isOfflineMode = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = Provider.of<List<CameraDescription>>(context, listen: false);
      if (cameras.isNotEmpty) {
        _controller = CameraController(
          cameras[0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() => _isInitialized = true);
          AppLogger.camera('Camera initialized', success: true);
        }
      } else {
        AppLogger.warning('No cameras available');
      }
    } catch (e) {
      AppLogger.camera('Camera initialization', success: false, details: e.toString());
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = 'Failed to initialize camera. Please check permissions.';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isAnalyzing = true;
      _isOfflineMode = false;
      _errorMessage = null;
    });

    try {
      final image = await _controller!.takePicture();
      AppLogger.camera('Picture captured', success: true, details: image.path);
      
      // Compress image before analysis
      final compressedPath = await ImageCompressor.compressImage(image.path);
      AppLogger.info('Image compressed');
      
      await _analyzeImage(compressedPath);
    } catch (e) {
      AppLogger.camera('Picture capture', success: false, details: e.toString());
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = 'Failed to capture image. Please try again.';
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        AppLogger.camera('Image selected from gallery', success: true, details: image.path);
        setState(() {
          _isAnalyzing = true;
          _isOfflineMode = false;
          _errorMessage = null;
        });
        
        // Compress image before analysis
        final compressedPath = await ImageCompressor.compressImage(image.path);
        AppLogger.info('Image compressed');
        
        await _analyzeImage(compressedPath);
      }
    } catch (e) {
      AppLogger.camera('Gallery selection', success: false, details: e.toString());
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = 'Failed to select image. Please try again.';
        });
      }
    }
  }

  Future<void> _analyzeImage(String imagePath) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    // Check if offline
    setState(() {
      _isOfflineMode = !apiService.isOnline;
    });

    final result = await apiService.analyzeImage(imagePath);

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
    } else if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = 'Analysis failed. Please try again.';
      });
    }
  }

  void _resetError() {
    setState(() {
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Crop'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _errorMessage != null
          ? _buildErrorState()
          : _isAnalyzing
              ? _buildAnalyzingState()
              : _isInitialized
                  ? _buildCameraPreview()
                  : _buildInitializingState(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: UIConstants.iconXLarge, color: Colors.red),
            const SizedBox(height: UIConstants.spacingLarge),
            Text(
              _errorMessage ?? 'An error occurred',
              style: const TextStyle(color: Colors.white, fontSize: UIConstants.fontSizeXLarge),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacingXLarge),
            ElevatedButton.icon(
              onPressed: _resetError,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(UIConstants.buttonMinWidth, UIConstants.buttonHeight),
                textStyle: const TextStyle(fontSize: UIConstants.fontSizeLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.green),
          const SizedBox(height: UIConstants.spacingLarge),
          const Text(
            'Analyzing...',
            style: TextStyle(color: Colors.white, fontSize: UIConstants.fontSizeXLarge),
          ),
          const SizedBox(height: UIConstants.spacingMedium),
          if (_isOfflineMode)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(
                  'Using offline mode',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Column(
      children: [
        Expanded(
          child: CameraPreview(_controller!),
        ),
        Container(
          padding: const EdgeInsets.all(UIConstants.paddingXLarge),
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(UIConstants.buttonMinWidth, UIConstants.buttonHeight),
                  textStyle: const TextStyle(fontSize: UIConstants.fontSizeLarge),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capture'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(UIConstants.buttonMinWidth, UIConstants.buttonHeight),
                  textStyle: const TextStyle(fontSize: UIConstants.fontSizeLarge),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInitializingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.green),
          SizedBox(height: UIConstants.spacingLarge),
          Text(
            'Initializing camera...',
            style: TextStyle(color: Colors.white, fontSize: UIConstants.fontSizeXLarge),
          ),
        ],
      ),
    );
  }
}
