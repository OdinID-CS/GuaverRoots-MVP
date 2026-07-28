# AI Integration Architecture

## Overview

GuaverRoots uses an on-device TensorFlow Lite inference pipeline wrapped in an abstract service interface. The UI talks to `ApiService`, which prefers local AI first, then optionally falls back to a remote FastAPI backend when online. This document describes the current implementation and how to extend it.

## Architecture

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
┌───────────────────────────┼───────────────────────────────┐
│                    ApiService                           │
│  - analyzeImage()                                     │
│  - analyzeAreaScan()                                  │
│  - Fallback chain: AI → API                         │
└───────────────────────────┼───────────────────────────────┘
                             │
           ┌─────────────────┼─────────────────┐
           │                 │                 │
┌─────────┴────────┐  ┌─────┴──────┐  ┌──────┴────────┐
│ AIInferenceService│  │   API      │  │  Feedback     │
│   (Interface)     │  │  Backend   │  │  Learning     │
│                   │  │  (Optional)│  │  Service      │
└─────────┬────────┘  └────────────┘  └───────────────┘
          │
    ┌─────┴─────┐
    │           │
┌───┴────┐  ┌──┴──────────┐
│ TFLite │  │ Future      │
│ Impl   │  │ Extensions  │
└────────┘  └─────────────┘
```

## Current Implementation

### Files

- `lib/services/ai/ai_inference_service.dart` — abstract interface
- `lib/services/ai/inference_service.dart` — TFLite inference implementation
- `lib/services/ai/model_loader.dart` — loads `.tflite` + labels from assets
- `lib/services/ai/image_preprocessor.dart` — 224×224 float32 normalization
- `lib/services/ai/prediction_parser.dart` — parses `Crop___Disease` labels
- `lib/services/ai/tiling_service.dart` — sliding window tiles with overlap
- `lib/services/ai/heatmap_service.dart` — IDW interpolation overlay
- `lib/services/recommendation_engine.dart` — disease-specific treatment rules
- `lib/services/feedback_service.dart` — scan correctness tracking and calibration

### Interface

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

### Inference Flow

1. `ModelLoader.loadInterpreter()` loads `assets/models/crop_disease_model.tflite`.
2. `ImagePreprocessor` decodes the image, resizes to 224×224, normalizes RGB to 0–1 float32.
3. `InferenceService.analyzeImage()` runs the interpreter, selects top class, parses label.
4. `PredictionParser` maps label to `crop`, `disease`, `isHealthy`, and severity.
5. `TilingService` splits wide images into 224×224 tiles with configurable overlap.
6. `HeatmapService` blends tile severity scores into a smooth overlay.

### Device Optimization

- `DevicePerformance.detect()` classifies the device as `high`, `medium`, or `low`.
- Low-end devices get:
  - reduced max area photos
  - lower tile overlap and smaller inference batches
  - reduced blur in glass cards
  - simplified splash screen

### Feedback + Learning Loop

- `FeedbackService` stores per-scan correctness in Hive.
- Farm profiles aggregate history by location, crop, and disease.
- `RecommendationEngine` uses local history to adjust confidence and urgency language.
- Future server-side retraining can use aggregated feedback to improve the bundled model.

## Model Requirements

- Input: `224×224×3` RGB float32 normalized image
- Output: probability distribution over disease classes
- Format: `.tflite` bundled in `assets/models/`
- Recommended size: < 20 MB
- Recommended optimization: INT8 quantization

## Adding a New AI Backend

To swap in a different model or backend:

1. Create a new class implementing `AIInferenceService`.
2. Register it in `ApiService` or a factory method.
3. No UI changes required.

## Troubleshooting

- **Model fails to load**: verify `assets/models/crop_disease_model.tflite` exists and is declared in `pubspec.yaml`.
- **Slow inference**: use INT8 quantization, reduce tile overlap, enable GPU/NNAPI delegates.
- **Poor accuracy**: validate labels file matches training classes, calibrate threshold per device tier.

## References

- [TensorFlow Lite Flutter Plugin](https://pub.dev/packages/tflite_flutter)
- [MobileNet Architecture](https://arxiv.org/abs/1704.04861)
- [TFLite Model Maker](https://www.tensorflow.org/lite/model_maker)
