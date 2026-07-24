# DEVELOPMENT_TASKS.md

# GuaverRoots MVP - Development Task Board

---

## 🎯 MVP Progress: 52%

---

## ✅ Completed

### Home Screen
**Status: Production Ready**

**Files:**
- `lib/screens/home_screen.dart`

**Features:**
- Navigation hub with Scan, Area Scan, and History
- Clean UI with constants-based styling
- Offline indicator
- Quick access to all main features

---

### History
**Status: Production Ready**

**Files:**
- `lib/screens/history_screen.dart`
- `lib/services/storage_service.dart`

**Features:**
- List view of all scan results
- Sorted by timestamp (newest first)
- Severity and confidence badges
- Delete all functionality
- Navigation to treatment details
- Image thumbnails with error handling

---

### Storage
**Status: Production Ready**

**Files:**
- `lib/services/storage_service.dart`
- `lib/models/scan_result.dart`

**Features:**
- Hive-based local storage
- CRUD operations for scan results
- Error handling and logging
- Offline-first architecture
- Data persistence across app sessions

---

### Camera
**Status: Production Ready**

**Files:**
- `lib/screens/scan_screen.dart`
- `lib/services/permission_service.dart`

**Features:**
- Camera initialization with error handling
- Photo capture with image compression
- Gallery selection
- API integration with mock fallback
- Offline mode indicator
- Permission handling (camera, storage)

---

### Area Scan Prototype
**Status: Functional**

**Files:**
- `lib/screens/area_scan_screen.dart`
- `lib/utils/image_compressor.dart`

**Features:**
- Multi-photo capture (max 9)
- Gallery selection
- Image compression for all photos
- Photo removal
- Grid layout with numbering
- API integration
- Simulated health status (needs AI integration)

---

### Additional Completed Infrastructure

**Treatment Screen** - Display disease results with confidence, severity, urgency, treatment recommendations

**Heatmap Screen** - Grid display with health legend and summary (currently using simulated health status)

**API Service** - Dio HTTP client with connectivity monitoring, timeout configuration, mock fallback

**Permission Service** - Centralized permission handling with permanently denied detection

**Image Compression** - Resize to max 1920x1080, JPEG quality 85%, batch compression

**Structured Logging** - Multi-level logging (debug, info, warning, error, critical) with API, storage, camera categories

**Custom Exceptions** - App-specific exception classes (Camera, API, Storage, Permission, Compression)

**Constants** - Centralized UI, API, and app-wide constants for maintainability

**Mock Data** - 8 disease samples for offline demo

**FastAPI Backend** - Python backend with /analyze and /analyze-area endpoints

---

## 🚧 Current Sprint

### TensorFlow Lite Integration
**Priority: Critical**
**Status: Not Started**

**Tasks:**
- [ ] Add tflite_flutter dependency to pubspec.yaml
- [ ] Download TensorFlow Lite disease classification model
- [ ] Add model file to assets directory
- [ ] Update pubspec.yaml to include model assets
- [ ] Create AI service class for model loading
- [ ] Implement model initialization in main.dart
- [ ] Create image preprocessing function
- [ ] Implement TensorFlow Lite inference
- [ ] Replace mock data with AI predictions in ApiService
- [ ] Add confidence calibration logic
- [ ] Implement fallback to mock on inference errors
- [ ] Add inference performance logging
- [ ] Test AI inference with sample images

**Dependencies:** None
**Estimated Effort:** 5-7 days

**Success Criteria:**
- App can detect 5+ common crop diseases with >80% confidence
- Inference completes in <3 seconds per image
- Graceful fallback to mock data on errors

---

### Recommendation Engine
**Priority: High**
**Status: Not Started**

**Tasks:**
- [ ] Define recommendation logic based on disease severity
- [ ] Create recommendation service
- [ ] Implement context-aware suggestions (weather, season)
- [ ] Add treatment cost estimation
- [ ] Integrate product availability (local stores)
- [ ] Add treatment effectiveness tracking
- [ ] Implement expert consultation integration
- [ ] Test recommendation accuracy

**Dependencies:** TensorFlow Lite Integration
**Estimated Effort:** 4-5 days

**Success Criteria:**
- Dynamic treatment recommendations based on detected disease
- Treatment suggestions include urgency and cost estimates
- User can provide feedback on treatment effectiveness

---

### Dashboard
**Priority: High**
**Status: Not Started**

**Tasks:**
- [ ] Create DashboardScreen widget
- [ ] Add farm health overview card
- [ ] Add recent activity feed
- [ ] Add quick action buttons (scan, area scan, history)
- [ ] Add statistics cards (total scans, diseases found)
- [ ] Implement farm health score calculation
- [ ] Add health score trend over time
- [ ] Add navigation to dashboard from HomeScreen
- [ ] Test dashboard performance

**Dependencies:** History Statistics
**Estimated Effort:** 3-4 days

**Success Criteria:**
- Dashboard shows meaningful farm health metrics
- Quick actions work seamlessly
- Statistics accurately reflect scan history

---

## 📋 Backlog

### Weather Intelligence
**Priority: Medium**
**Status: Not Started**

**Tasks:**
- [ ] Add weather API integration
- [ ] Fetch weather data for farm location
- [ ] Display weather conditions on dashboard
- [ ] Integrate weather into disease risk assessment
- [ ] Add weather-based treatment recommendations
- [ ] Implement weather alerts for disease-prone conditions

**Dependencies:** GPS Mapping, Dashboard
**Estimated Effort:** 3-4 days

---

### GPS Mapping
**Priority: Medium**
**Status: Not Started**

**Tasks:**
- [ ] Add geolocator dependency
- [ ] Add location permission to PermissionService
- [ ] Request location permission on app start
- [ ] Capture GPS location on photo capture
- [ ] Add location field to ScanResult model
- [ ] Display location in TreatmentScreen
- [ ] Create farm profile with location
- [ ] Implement location-based disease tracking

**Dependencies:** PermissionService update
**Estimated Effort:** 2-3 days

---

### Cloud Sync
**Priority: Medium**
**Status: Not Started**

**Tasks:**
- [ ] Design cloud sync architecture
- [ ] Add authentication service
- [ ] Implement cloud storage integration
- [ ] Add sync conflict resolution
- [ ] Implement offline-first sync strategy
- [ ] Add sync status indicators
- [ ] Test sync reliability
- [ ] Add data export/import

**Dependencies:** None
**Estimated Effort:** 5-7 days

---

### Notifications
**Priority: Medium**
**Status: Not Started**

**Tasks:**
- [ ] Add local_notifications dependency
- [ ] Add notification permission to PermissionService
- [ ] Schedule treatment reminders based on urgency
- [ ] Create reminder management UI
- [ ] Add reminder history view
- [ ] Implement notification scheduling
- [ ] Add notification preferences in settings
- [ ] Test notification delivery

**Dependencies:** Settings screen, Recommendation Engine
**Estimated Effort:** 2-3 days

---

## 🎯 MVP Success Criteria

### Must Have (Week 1-2)
- [ ] Real AI-powered disease detection (TensorFlow Lite integrated)
- [ ] Heatmap shows actual health status from AI (not simulated)
- [ ] Recommendation engine provides dynamic treatment suggestions
- [ ] Dashboard displays farm health overview and statistics
- [ ] No critical crashes or bugs
- [ ] Smooth loading states throughout
- [ ] Works offline with graceful fallback

### Nice to Have (Week 2-3)
- [ ] Weather intelligence integrated
- [ ] GPS location tagging for scans
- [ ] Treatment reminders implemented
- [ ] Cloud sync for data backup

### Success Metrics
- App can detect 5+ common crop diseases with >80% confidence
- Both single and area scan work end-to-end in <30 seconds
- Heatmap accurately reflects AI health predictions
- Dashboard provides actionable farm health insights
- Recommendations are contextually relevant
- Zero crashes during demo session
- Smooth UX with clear loading indicators

---

## 📊 Sprint Planning

### Week 1: AI Integration
**Focus:** TensorFlow Lite integration and real disease detection

**Deliverables:**
- TensorFlow Lite model integrated
- Real AI predictions replacing mock data
- Heatmap using actual health status
- Basic camera UX improvements (flash, preview)

---

### Week 2: User Experience
**Focus:** Dashboard and Recommendation Engine

**Deliverables:**
- Dashboard screen with farm health overview
- Recommendation engine with dynamic suggestions
- Treatment effectiveness tracking
- Basic GPS location tagging

---

### Week 3: Polish & Enhancement
**Focus:** Weather, Notifications, Cloud Sync

**Deliverables:**
- Weather intelligence integration
- Treatment reminders
- Cloud sync foundation
- Performance optimization
- Bug fixes and polish

---

**Document Version:** 3.0  
**Last Updated:** 2026-07-23  
**Project:** GuaverRoots MVP  
**Current Focus:** TensorFlow Lite Integration  
**Status:** Foundation Complete (52%), AI Integration In Progress
