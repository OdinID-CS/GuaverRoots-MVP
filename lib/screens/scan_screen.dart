import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';
import '../core/exceptions/app_exceptions.dart';
import '../core/constants/app_constants.dart';
import '../core/logging/app_logger.dart';
import '../utils/image_compressor.dart';
import 'treatment_screen.dart';
import '../widgets/glass_card.dart';

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
      await PermissionService.requestCamera();
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
    } on PermissionException catch (e) {
      AppLogger.permission('Camera initialization blocked', false);
      AppLogger.error('Camera initialization blocked', error: e, tag: 'ScanScreen');
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = e.message;
        });
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

      final compressedPath = await ImageCompressor.compressImage(image.path);
      AppLogger.info('Image compressed');

      final location = await _getCurrentLocation();

      await _analyzeImage(compressedPath, location: location);
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

        final compressedPath = await ImageCompressor.compressImage(image.path);
        AppLogger.info('Image compressed');

        final location = await _getCurrentLocation();

        await _analyzeImage(compressedPath, location: location);
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
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception("Location fetch timed out"),
      );

      return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    } catch (e) {
      AppLogger.warning('Unable to get current location', tag: 'ScanScreen', error: e.toString());
      return null;
    }
  }

  Future<void> _analyzeImage(String imagePath, {String? location}) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    setState(() {
      _isOfflineMode = !apiService.isOnline;
    });

    final result = await apiService.analyzeImage(imagePath, location: location);

    if (result != null && mounted) {
      await StorageService.saveScanResult(result);

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TreatmentScreen(scanResult: result),
          ),
        );
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
          });
        }
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000000),
              Color(0xFF0D1B0E),
              Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: _errorMessage != null
              ? _buildErrorState()
              : _isAnalyzing
                  ? _buildAnalyzingState()
                  : _isInitialized
                      ? _buildCameraPreview()
                      : _buildInitializingState(),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(AppColors.redPrimary).withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.error_outline, size: 48, color: Color(AppColors.redPrimary)),
            ),
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
                backgroundColor: const Color(AppColors.forestGreen),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(AppColors.limeGreen).withValues(alpha: 0.12),
            ),
            child: const CircularProgressIndicator(color: Color(AppColors.limeGreen), strokeWidth: 3),
          ),
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.0),
                const Color(0xFF000000).withValues(alpha: 0.9),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GlassCard(
                onTap: _pickFromGallery,
                opacity: 0.35,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.photo_library, color: Colors.white, size: UIConstants.iconLarge),
                    const SizedBox(width: 8),
                    Text('Gallery', style: TextStyle(color: Colors.white, fontSize: UIConstants.fontSizeMedium)),
                  ],
                ),
              ),
              GlassCard(
                onTap: _takePicture,
                opacity: 0.55,
                borderColor: const Color(AppColors.limeGreen).withValues(alpha: 0.5),
                shadows: [
                  BoxShadow(
                    color: const Color(AppColors.limeGreen).withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.camera_alt, color: Color(AppColors.limeGreen), size: UIConstants.iconLarge),
                    const SizedBox(width: 8),
                    Text('Capture', style: TextStyle(color: Colors.white, fontSize: UIConstants.fontSizeMedium)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInitializingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(AppColors.limeGreen).withValues(alpha: 0.12),
            ),
            child: const CircularProgressIndicator(color: Color(AppColors.limeGreen), strokeWidth: 3),
          ),
          const SizedBox(height: UIConstants.spacingLarge),
          Text(
            'Initializing camera...',
            style: TextStyle(color: Colors.grey[400], fontSize: UIConstants.fontSizeXLarge),
          ),
        ],
      ),
    );
  }
}