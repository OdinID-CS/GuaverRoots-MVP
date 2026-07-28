# AI Enablement Checklist

Use this checklist when updating the bundled TensorFlow Lite model or retraining for better accuracy.

## Model Training
- [ ] Export `.tflite` model
- [ ] Validate accuracy (>80% on held-out test set)
- [ ] Apply INT8 quantization for mobile performance
- [ ] Verify input shape is `(1, 224, 224, 3)`
- [ ] Verify output shape matches disease classes
- [ ] Create updated `labels.txt` if class names changed
- [ ] Test inference with sample images on desktop
- [ ] Measure inference latency on target device tier

## Model Deployment
- [ ] Place new `.tflite` in `assets/models/`
- [ ] Update `pubspec.yaml` assets if needed
- [ ] Run `flutter pub get`
- [ ] Run `flutter pub run build_runner build`
- [ ] Verify app starts without crashes
- [ ] Verify first-run model loading logs
- [ ] Test single scan on at least 5 sample images
- [ ] Test area scan on at least 2 wide field images

## Feedback Pipeline
- [ ] Capture user feedback after each scan
- [ ] Store feedback locally in Hive
- [ ] Aggregate feedback by location/crop/disease
- [ ] Export anonymized feedback for server retraining
- [ ] Use feedback to calibrate local confidence thresholds

## Notifications
- [ ] Schedule treatment reminders from scan urgency
- [ ] Handle denied notification permissions gracefully
- [ ] Allow users to cancel or reschedule reminders
- [ ] Test reminder delivery across device tiers

## Localization
- [ ] Add all translated strings to ARB files
- [ ] Verify locale fallback when translation is missing
- [ ] Test TTS voice output in each supported language
- [ ] Verify RTL and font rendering on low-end devices

## Performance
- [ ] Measure memory usage during single scan
- [ ] Measure memory usage during area scan with 9 images
- [ ] Measure heatmap rendering frame rate
- [ ] Verify app does not exceed 200 MB RAM usage on low-end device
- [ ] Verify splash-to-home transition completes within 4 seconds

## Release
- [ ] Run `flutter analyze`
- [ ] Run `flutter test`
- [ ] Update `CHANGELOG.md`
- [ ] Tag release in git
- [ ] Build APK/AAB and distribute to testers
