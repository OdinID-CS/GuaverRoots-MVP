# AI Integration Architecture

## Overview

The GuaverRoots app is designed with a pluggable AI inference architecture. The UI and business logic are decoupled from the actual AI implementation through an abstract interface. This allows seamless replacement of the mock implementation with real TensorFlow Lite inference without modifying any UI code.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ ScanScreen   │  │AreaScanScreen│  │HistoryScreen │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                 │              │
└─────────┼─────────────────┼─────────────────┼──────────────┘
          │                 │                 │
          └─────────────────┼─────────────────┘
                            │
┌───────────────────────────┼────────────────————————───┐
│                    ApiService                           │
│  - analyzeImage()                                     │
│  - analyzeAreaScan()                                  │
│  - Fallback chain: AI → API → Mock                   │
└───────────────────────────┼────────────────————————───┘
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
┌─────────┴────────┐  ┌─────┴──────┐  ┌──────┴────────┐
│ AIInferenceService│  │   API      │  │  Legacy Mock  │
│   (Interface)     │  │  Backend   │  │   Fallback    │
└─────────┬────────┘  └────────────┘  └───────────────┘
          │
    ┌─────┴─────┐
    │           │
┌───┴────┐  ┌──┴──────────┐
│ Mock   │  │ TFLite      │
│ Impl   │  │ Impl (Future)│
└────────┘  └─────────────┘
```

## File Structure

```
lib/
├── models/
│   ├── prediction.dart              # Prediction & AreaPrediction models
│   └── scan_result.dart             # Existing scan result model
├── services/
│   ├── api_service.dart             # Updated to use AI abstraction
│   └── ai/
│       ├── ai_inference_service.dart    # Abstract interface
│       ├── mock_inference_service.dart  # Mock implementation (current)
│       └── tflite_inference_service.dart # TFLite implementation (future)
└── assets/
    └── models/
        ├── crop_disease_model.tflite   # TensorFlow Lite model (future)
        └── labels.txt                   # Disease labels (future)
```

## Current Implementation

### AI Inference Interface

**File:** `lib/services/ai/ai_inference_service.dart`

The abstract interface defines the contract for all AI implementations:

```dart
abstract class AIInferenceService {
  Future<bool> initialize();
  Future<Prediction?> analyzeImage(String imagePath);
  Future<AreaPrediction?> analyzeArea(List<String> imagePaths);
  bool get isReady;
  String get serviceName;
  Future<void> dispose();
}
```

### Prediction Model

**File:** `lib/models/prediction.dart`

Standardized output format for all AI implementations:

```dart
class Prediction {
  final String crop;              // e.g., "tomato", "maize"
  final String disease;          // e.g., "Leaf Rust", "Healthy"
  final double confidence;       // 0.0 to 1.0
  final String severity;         // "None", "Low", "Moderate", "High"
  final String? recommendationId; // Optional treatment lookup ID
}
```

### Mock Implementation

**File:** `lib/services/ai/mock_inference_service.dart`

Current implementation that returns realistic mock data. This allows the app to function for demo purposes while the real model is being trained.

### API Service Integration

**File:** `lib/services/api_service.dart`

The ApiService now uses a fallback chain:

1. **AI Inference** (first priority) - Works offline, uses AIInferenceService
2. **API Backend** (second priority) - Cloud-based analysis if online
3. **Legacy Mock** (final fallback) - Original mock data

```dart
Future<ScanResult?> analyzeImage(String imagePath) async {
  // Try AI inference first (works offline)
  if (_aiService.isReady) {
    final prediction = await _aiService.analyzeImage(imagePath);
    if (prediction != null) {
      return _convertPredictionToScanResult(prediction, imagePath, false);
    }
  }
  
  // Fallback to API if online
  if (_isOnline) {
    // ... API call
  }
  
  // Final fallback to legacy mock data
  return _getMockResult(imagePath);
}
```

## Future TensorFlow Lite Integration

### Step 1: Add Dependencies

**File:** `pubspec.yaml`

```yaml
dependencies:
  tflite_flutter: ^0.10.4
  tflite_flutter_helper: ^0.3.0  # Optional, for image preprocessing
```

### Step 2: Place Model Files

**Directory:** `assets/models/`

Place the following files in the assets directory:

```
assets/models/
├── crop_disease_model.tflite    # TensorFlow Lite model file
└── labels.txt                    # Disease labels (one per line)
```

**Update pubspec.yaml:**

```yaml
flutter:
  assets:
    - assets/models/
```

### Step 3: Create TFLite Implementation

**File:** `lib/services/ai/tflite_inference_service.dart`

```dart
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/prediction.dart';
import 'ai_inference_service.dart';

class TFLiteInferenceService implements AIInferenceService {
  late Interpreter _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  @override
  Future<bool> initialize() async {
    try {
      // Load model
      _interpreter = await Interpreter.fromAsset('assets/models/crop_disease_model.tflite');
      
      // Load labels
      _labels = await File('assets/models/labels.txt').readAsLines();
      
      _isInitialized = true;
      return true;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }

  @override
  Future<Prediction?> analyzeImage(String imagePath) async {
    if (!_isInitialized) return null;
    
    // 1. Load and preprocess image
    final imageBytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(imageBytes);
    final input = _preprocessImage(image);
    
    // 2. Run inference
    final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
    _interpreter.run(input, output);
    
    // 3. Process output
    final results = output[0] as List<double>;
    final maxIndex = results.indexOf(results.reduce((a, b) => a > b ? a : b));
    
    // 4. Map to Prediction
    return Prediction(
      crop: 'detected_crop',  // Or infer from model
      disease: _labels[maxIndex],
      confidence: results[maxIndex],
      severity: _mapToSeverity(results[maxIndex]),
      recommendationId: _generateRecommendationId(_labels[maxIndex]),
    );
  }

  @override
  Future<AreaPrediction?> analyzeArea(List<String> imagePaths) async {
    final predictions = <Prediction>[];
    for (final path in imagePaths) {
      final prediction = await analyzeImage(path);
      if (prediction != null) {
        predictions.add(prediction);
      }
    }
    return AreaPrediction.fromPredictions(predictions);
  }

  @override
  bool get isReady => _isInitialized;

  @override
  String get serviceName => 'TFLiteInferenceService';

  @override
  Future<void> dispose() async {
    await _interpreter.close();
    _isInitialized = false;
  }

  // Helper methods for preprocessing, severity mapping, etc.
}
```

### Step 4: Switch to TFLite Implementation

**File:** `lib/services/api_service.dart`

Change one line in `_initAIService()`:

```dart
// Before:
_aiService = MockInferenceService();

// After:
_aiService = TFLiteInferenceService();
```

That's it! The UI and all other code remain unchanged.

## Model Requirements

### TensorFlow Lite Model Specifications

- **Input:** 224x224x3 RGB image (standard MobileNet input)
- **Output:** Probability distribution over disease classes
- **Format:** TensorFlow Lite (.tflite)
- **Size:** < 20MB recommended for mobile performance
- **Quantization:** INT8 recommended for faster inference

### Labels File Format

**File:** `assets/models/labels.txt`

One label per line, matching the output classes:

```
Healthy
Leaf Rust
Powdery Mildew
Early Blight
Late Blight
Bacterial Leaf Spot
...
```

### Severity Mapping

The TFLite implementation should map confidence scores to severity levels:

```dart
String _mapToSeverity(double confidence) {
  if (disease == 'Healthy') return 'None';
  if (confidence > 0.8) return 'High';
  if (confidence > 0.6) return 'Moderate';
  return 'Low';
}
```

## Testing Strategy

### Unit Tests

Test the TFLite implementation with known images:

```dart
test('TFLite inference returns valid prediction', () async {
  final service = TFLiteInferenceService();
  await service.initialize();
  
  final prediction = await service.analyzeImage('test_images/leaf_rust.jpg');
  
  expect(prediction, isNotNull);
  expect(prediction.confidence, greaterThan(0.5));
  expect(prediction.severity, isIn(['Low', 'Moderate', 'High']));
});
```

### Integration Tests

Test the full flow from UI to AI:

1. Capture image in ScanScreen
2. Verify AI service is called
3. Verify Prediction is converted to ScanResult
4. Verify TreatmentScreen displays results

### Performance Tests

- Inference time should be < 3 seconds per image
- Memory usage should be < 100MB
- App should not freeze during inference

## Benefits of This Architecture

1. **Zero UI Changes** - Switching AI implementations requires no UI modifications
2. **Offline-First** - AI inference works without internet
3. **Fallback Chain** - Multiple fallback options ensure reliability
4. **Testable** - Easy to unit test each component independently
5. **Future-Proof** - Can swap in cloud AI, different models, or hybrid approaches
6. **Demo Ready** - Mock implementation allows immediate demos while model trains

## Migration Path

1. **Current State** - MockInferenceService provides realistic demo data
2. **Model Training** - Train TensorFlow Lite model offline
3. **Integration** - Implement TFLiteInferenceService
4. **Testing** - Test with real images and edge cases
5. **Deployment** - Switch one line in ApiService
6. **Monitoring** - Monitor inference performance and accuracy

## Troubleshooting

### Model Fails to Load

- Verify model is in `assets/models/`
- Check pubspec.yaml includes assets
- Ensure model file is valid .tflite format

### Inference Too Slow

- Check model size (aim for < 20MB)
- Use INT8 quantization
- Consider reducing input resolution
- Test on target device hardware

### Poor Accuracy

- Verify training data matches deployment conditions
- Check label file matches model output classes
- Test with diverse image conditions
- Consider ensemble of multiple models

## References

- [TensorFlow Lite Flutter Plugin](https://pub.dev/packages/tflite_flutter)
- [MobileNet Model Architecture](https://arxiv.org/abs/1704.04861)
- [TensorFlow Lite Model Maker](https://www.tensorflow.org/lite/model_maker)
