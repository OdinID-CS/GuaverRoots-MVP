# GuaverRoots

Offline-first crop health app for smallholder farmers in Africa.

## Features

- **Single Scan**: Take a photo of a crop for instant AI disease detection
- **Area Scan**: Capture multiple photos to generate a field-level health heat map
- **Treatment Recommendations**: Get actionable treatment advice with urgency indicators
- **Farm History**: Track all scans and monitor disease progression over time
- **Offline-First**: Works without internet connection using local AI models

## Tech Stack

- **Flutter**: Cross-platform mobile framework
- **Hive**: Local NoSQL database for offline storage
- **Dio**: HTTP client for API calls to FastAPI backend
- **Camera**: Camera access for photo capture
- **Provider**: State management

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extension
- Android device/emulator

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate Hive adapters:
   ```bash
   flutter pub run build_runner build
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── scan_result.dart      # Data model for scan results
├── services/
│   ├── api_service.dart      # API communication with backend
│   └── storage_service.dart  # Local storage management
└── screens/
    ├── home_screen.dart      # Main navigation screen
    ├── scan_screen.dart      # Single photo capture
    ├── area_scan_screen.dart # Multi-photo area scan
    ├── treatment_screen.dart # Treatment recommendations
    ├── heatmap_screen.dart   # Area heat map visualization
    └── history_screen.dart   # Farm history list
```

## API Integration

The app is designed to work with a FastAPI backend. Configure the backend URL in `lib/services/api_service.dart`:

```dart
final String _baseUrl = 'http://your-backend-url:8000';
```

### API Endpoints

- `POST /analyze` - Analyze single image
- `POST /analyze-area` - Analyze multiple images for area scan

## Offline Mode

When offline, the app returns mock data for demonstration purposes. The local storage ensures all scan history is preserved regardless of connectivity.

## Permissions

The app requires the following permissions (configured in AndroidManifest.xml):
- Camera
- Read/Write External Storage

## License

MIT License
