# GuaverRoots MVP - Development Task Board

---

## MVP Progress: ~75%

---

## Completed

### Foundation
- Flutter 3.x + Dart 3.x setup with Provider state management
- Hive + generated adapters for ScanResult and WeatherData
- Structured logging, custom exceptions, centralized constants
- Connectivity monitoring, camera init, permission service

### AI Integration
- TensorFlow Lite inference via `tflite_flutter`
- Model loader, image preprocessor, prediction parser
- Sliding-window tiling service for area scans
- Heatmap service with IDW interpolation
- Off-thread preprocessing via Isolate
- Device-aware performance mode for low-end devices

### Screens
- **Splash Screen**: Animated logo, text, motion graphics, fade transition
- **Home Screen**: Weather risk card, action buttons, glassmorphism UI
- **Dashboard**: Farm health score, statistics, recent scan, quick actions
- **Scan Screen**: Camera preview, gallery, compression, GPS location, analysis, treatment navigation
- **Area Scan Screen**: Multi-photo grid (max 9, dynamic by device tier), numbered thumbnails, tiling, heatmap navigation
- **Treatment Screen**: Disease details, confidence, severity, urgency, recommendations, reminders, location
- **Heatmap Screen**: Tiled overlay, opacity slider, legend, area health summary
- **History Screen**: Scan list, badges, pull-to-refresh, clear-all, detail navigation

### Services
- API service with AI-first fallback chain
- Weather service with Open-Meteo + 60-minute Hive cache
- Storage service CRUD for ScanResult
- Permission service for camera/storage with permanently-denied handling
- Recommendation engine with disease-specific rules and urgency mapping
- Notification service for treatment reminders
- Feedback service for scan correctness and farm calibration
- Device performance detector (low/medium/high)

### UI/UX
- Glassmorphism design system with `GlassCard`
- Forest Green / Lime Green / White / Black palette
- Poppins typography via Google Fonts
- Low-end device gating for blur, particles, tile overlap, batch sizes
- Responsive layout and scrollable content on all screens

### Data & Offline
- ScanResult stores: image path, disease, confidence, severity, treatment, urgency, location, heatmap points
- WeatherData cached with timestamp + TTL
- All scan history available offline
- Location tagging on capture via Geolocator

---

## In Progress

### Localization & Voice
- ARB files for English, Twi, Ga, Ewe, Hausa, Dagbani
- Localization delegates + language switcher UI
- TTS integration for reading treatment results aloud

### Farm Learning
- Feedback UI after scan completion
- Farm profile aggregation by location/disease
- Confidence calibration based on user feedback history

---

## Backlog

### Notifications Polish
- Notification preferences UI (quiet hours, frequency)
- Reminder history view
- Per-scan reminder scheduling from history

### Cloud Sync
- Optional user auth
- Remote backup of scan history
- Model versioning and over-the-air updates
- Aggregated feedback upload for model improvement

### Advanced AI
- Quantized model evaluation and swap-in
- GPU/NNAPI delegate support
- Background tile filtering to skip sky/soil patches
- Parallel tile inference batching

## Success Criteria

- App can detect 5+ common crop diseases with >80% confidence
- Both single and area scan work end-to-end in <30 seconds on mid-range devices
- Heatmap accurately reflects AI health predictions
- Dashboard provides actionable farm health insights
- Recommendations are contextually relevant
- Zero crashes during normal demo session
- Smooth UX with clear loading indicators
- Works fully offline after first launch
- Supports at least 5 local languages with voice output
