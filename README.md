# GuaverRoots

Offline-first crop health assistant for smallholder farmers in Africa. GuaverRoots combines on-device AI disease detection, field-level area scanning with heatmaps, farm history, weather intelligence, smart recommendations, and multi-language voice guidance — all built to work without reliable internet.

## Features

- **Single Scan**: Capture or select a crop photo for instant on-device AI disease detection using TensorFlow Lite.
- **Area Scan**: Capture up to 9 field photos, generate a multi-photo disease intensity heatmap, and view combined field health statistics.
- **Treatment Recommendations**: Receive disease-specific treatment guidance with urgency indicators, preventive measures, and follow-up reminders.
- **Farm Dashboard**: Review farm health scores, scan statistics, most recent activity, and quick actions.
- **Farm History**: Browse past scans with severity/confidence badges, timestamps, location tags, and detail navigation.
- **Weather Intelligence**: Fetch local weather via Open-Meteo, cache results offline, and see rule-based disease risk on the home screen.
- **Offline-First**: AI inference runs fully on-device; scan history, weather cache, and recommendations remain available without connectivity.
- **Low-End Support**: Automatic device-tier detection reduces tile count, inference batching, and UI effects on weaker hardware.
- **Multi-Language + Voice**: Supports English plus Ghanaian local languages with text-to-speech for treatment results.

## Tech Stack

- **Flutter** 3.x + **Dart** 3.x
- **Provider** for state management
- **Hive** + Hive adapters for offline persistence
- **tflite_flutter** for on-device inference
- **camera** + **image_picker** for photo capture
- **geolocator** for GPS location tagging
- **flutter_local_notifications** + **timezone** for reminders
- **google_fonts** + glassmorphism UI
- **dio** + **connectivity_plus** for optional backend/API fallback
- **flutter_tts** for voice guidance
- **intl** + localization delegates for Ghanaian languages

## Project Structure

```
lib/
├── main.dart                               # App entry, Hive init, splash → home bootstrap
├── config/
│   └── api_config.dart                     # FastAPI backend base URL + endpoints
├── core/
│   ├── constants/
│   │   └── app_constants.dart              # UI sizes, colors, date formats
│   ├── exceptions/
│   │   └── app_exceptions.dart             # App exception hierarchy
│   └── logging/
│       └── app_logger.dart                 # Structured debug/info/warning/error logs
├── models/
│   ├── prediction.dart                      # Prediction / AreaPrediction models
│   ├── scan_result.dart                     # Hive ScanResult model + adapters
│   ├── scan_result.g.dart
│   └── weather_data.dart                    # Hive WeatherData model + adapter
├── providers/
│   └── app_providers.dart                   # HistoryProvider with farm statistics
├── screens/
│   ├── splash_screen.dart                   # Branded animated entry screen
│   ├── home_screen.dart                     # Weather risk + navigation actions
│   ├── dashboard_screen.dart                # Farm health stats + quick actions
│   ├── scan_screen.dart                     # Camera preview, capture, analysis
│   ├── area_scan_screen.dart                # Multi-photo grid, tiling, heatmap
│   ├── treatment_screen.dart                # Detailed disease + recommendation card
│   ├── heatmap_screen.dart                  # Heatmap overlay, opacity, legend
│   └── history_screen.dart                  # Past scans, badges, clear-all
├── services/
│   ├── api_service.dart                     # Connectivity, AI/API orchestration
│   ├── weather_service.dart                 # Open-Meteo, caching, risk rules
│   ├── storage_service.dart                 # Hive CRUD for ScanResult
│   ├── permission_service.dart              # Camera/storage permission wrappers
│   ├── recommendation_engine.dart           # Disease-specific treatment engine
│   ├── notification_service.dart            # Local reminders for treatments
│   ├── feedback_service.dart                # Scan feedback + farm calibration
│   └── ai/
│       ├── ai_inference_service.dart        # Abstract inference interface
│       ├── inference_service.dart           # TFLite interpreter + preprocessing
│       ├── model_loader.dart                # Asset model + label loading
│       ├── image_preprocessor.dart          # 224x224 float32 normalization
│       ├── prediction_parser.dart           # Label parsing + severity mapping
│       ├── tiling_service.dart              # Sliding-window tiles + aggregation
│       ├── heatmap_service.dart             # IDW interpolation for overlay
│       └── ai_result.dart                   # Inference result model
├── utils/
│   ├── image_compressor.dart                # Resize + JPEG compression
│   ├── device_performance.dart              # Low/medium/high device tier detection
│   └── image_preprocessor_isolate.dart      # Off-thread image preprocessing
├── widgets/
│   └── glass_card.dart                      # Reusable glassmorphism card
└── l10n/
    ├── app_localizations.dart               # Localization delegate + supported locales
    ├── app_en.arb                           # English
    ├── app_tw.arb                           # Twi
    ├── app_ga.arb                           # Ga
    ├── app_ew.arb                           # Ewe
    ├── app_ha.arb                           # Hausa
    └── app_da.arb                           # Dagbani
```

## Getting Started

### Prerequisites

- Flutter SDK 3.0.0+
- Android Studio / VS Code with Flutter extension
- Android or iOS device/emulator

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Generate Hive adapters if needed:
   ```bash
   flutter pub run build_runner build
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Screens

- **Splash** → animated brand screen with motion graphics
- **Home** → weather risk card + Scan, Area Scan, History, Dashboard actions
- **Dashboard** → farm health score, stats, recent scan, quick actions
- **Scan** → live camera, gallery pick, compression, AI analysis, treatment view
- **Area Scan** → up to 9 photos in a numbered grid, tiling AI, heatmap output
- **Treatment** → disease, confidence, severity, urgency, smart recommendations, reminder button, location
- **Heatmap** → tiled overlay with opacity slider and area health summary
- **History** → scan list with badges, pull-to-refresh, delete-all, detail navigation

## Offline Behavior

- AI inference is fully on-device via TensorFlow Lite.
- Weather results are cached in Hive for 60 minutes.
- Scan history persists locally with generated Hive adapters.
- Recommendations work offline using the bundled disease-response engine.
- Voice guidance can be cached per language on device.

## Permissions

- Camera
- Photos / Storage
- Location (optional, for GPS tagging)
- Notifications (optional, for treatment reminders)
- Microphone not required; voice guidance uses system TTS only.

## Model

- Input: `224×224×3` RGB normalized float32
- Output: class probabilities over supported crop diseases
- Format: `.tflite`, bundled in `assets/models/`
- Optimization: Prefer INT8 quantized model for low-end devices

## Languages

- English
- Twi
- Ga
- Ewe
- Hausa
- Dagbani

## Feedback & Learning

- After each scan, users can confirm whether the prediction was correct.
- The app tracks treatment outcomes and calibration data per farm.
- Over time, recommendation confidence can be adjusted based on local history.
- Future versions can use aggregated feedback to improve model accuracy.

## Contributing

Pull requests are welcome. Please open an issue first to discuss major changes.

## License

MIT License
