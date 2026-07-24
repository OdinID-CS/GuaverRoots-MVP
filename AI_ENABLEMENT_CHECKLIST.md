# Real AI Inference Enablement Checklist

This checklist outlines all requirements before switching from MockInferenceService to real TensorFlow Lite inference in the Flutter app.

## Prerequisites

### Model Training
- [x] Train TensorFlow Lite model on crop disease dataset
- [x] Validate model accuracy (>80% on test set)
- [x] Export model to .tflite format
- [x] Apply INT8 quantization for mobile performance
- [x] Ensure model file size < 20MB
- [x] Test model inference on desktop Python environment
- [x] Create labels.txt file matching model output classes
- [x] Document model input/output specifications

### Model File Placement
- [ ] Place `model.tflite` in project root or `models/model.tflite`
- [ ] Verify model file is accessible by FastAPI backend
- [ ] Test model loading with `load_model()` function
- [ ] Verify model input shape is (1, 224, 224, 3)
- [ ] Verify model output shape matches 39 classes

## Python Backend Implementation

### Dependencies
- [x] Add `numpy==1.24.3` to requirements.txt
- [x] Add `Pillow==10.0.0` to requirements.txt
- [x] Add `tflite-runtime==2.14.0` to requirements.txt
- [x] Add `groq==0.4.1` to requirements.txt
- [ ] Run `pip install -r requirements.txt`
- [ ] Verify no dependency conflicts

### Model Loading
- [x] Implement `load_model()` function
- [x] Add tflite_runtime import with tensorflow.lite fallback
- [x] Load model on app startup
- [x] Add error handling for model loading failures
- [ ] Test model loading with actual model file

### Image Preprocessing
- [x] Implement `preprocess_image()` function
- [x] Resize image to 224x224
- [x] Convert to RGB
- [x] Normalize to 0-1 (divide by 255)
- [x] Shape to (1, 224, 224, 3)
- [x] Convert to float32
- [ ] Test preprocessing with sample images

### Class Name Parsing
- [x] Implement `parse_class_name()` function
- [x] Parse Crop___DiseaseName format
- [x] Replace underscores with spaces
- [x] Handle special cases (Pepper,_bell)
- [x] Detect healthy status
- [ ] Test parsing with all 39 class names

### Severity Inference
- [x] Implement `infer_severity()` function
- [x] Map healthy → "None"
- [x] Map confidence > 0.8 → "High"
- [x] Map confidence > 0.6 → "Moderate"
- [x] Map confidence < 0.6 → "Low"
- [ ] Test severity mapping logic

### Groq API Integration
- [x] Add groq import
- [x] Implement `generate_treatment_with_groq()` function
- [x] Add API key configuration via environment variable
- [x] Initialize client on startup
- [x] Add fallback for missing API key
- [x] Add error handling for API failures
- [x] Set GROQ_API_KEY environment variable
- [ ] Test Groq API integration

### /analyze Endpoint
- [x] Update endpoint to use real model
- [x] Add model loading check
- [x] Implement inference pipeline
- [x] Get argmax class and confidence
- [x] Parse class name
- [x] Infer severity
- [x] Call Groq API for treatment
- [x] Return matching DiagnosisResult schema
- [x] Add fallback to mock data if model fails
- [ ] Test endpoint with real images
- [ ] Test endpoint with invalid images
- [ ] Test endpoint without model file

## Testing

### Unit Tests
- [ ] Test `preprocess_image()` with various image formats
- [ ] Test `parse_class_name()` with all 39 classes
- [ ] Test `infer_severity()` with various confidence values
- [ ] Test model loading with valid/invalid model files
- [ ] Test Groq API integration (with and without API key)

### Integration Tests
- [ ] Test /analyze endpoint with healthy plant image
- [ ] Test /analyze endpoint with diseased plant image
- [ ] Test /analyze endpoint with background image
- [ ] Test /analyze endpoint with non-image file
- [ ] Test /analyze endpoint without model file (fallback)
- [ ] Test /analyze endpoint without Groq API key (fallback)

### Performance Tests
- [ ] Measure inference time per image (target: < 3 seconds)
- [ ] Test with multiple concurrent requests
- [ ] Verify memory usage is reasonable
- [ ] Test on target deployment environment

## Deployment

### Environment Configuration
- [ ] Set MODEL_PATH environment variable if needed
- [ ] Set GROQ_API_KEY environment variable
- [ ] Create .env file for local development
- [ ] Document environment variables in README

### Model Deployment
- [ ] Place model.tflite in production location
- [ ] Verify model file permissions
- [ ] Test model loading in production environment
- [ ] Monitor model loading on startup

### API Deployment
- [ ] Deploy FastAPI backend with new dependencies
- [ ] Verify /analyze endpoint is accessible
- [ ] Test endpoint with real images
- [ ] Monitor API response times
- [ ] Set up error monitoring

## Documentation

### Code Documentation
- [x] Add doc comments to all new functions
- [x] Document model input/output specifications
- [x] Document preprocessing steps
- [x] Document class name parsing logic
- [x] Document severity mapping rules
- [x] Document Groq API integration

### User Documentation
- [ ] Update README.md with AI capabilities
- [ ] Document supported crop types (39 classes)
- [ ] Document supported diseases
- [ ] Document accuracy metrics
- [ ] Add troubleshooting section for AI issues
- [ ] Document environment variable setup

### Technical Documentation
- [ ] Document model training process
- [ ] Document model version and training data
- [ ] Document performance benchmarks
- [ ] Document known limitations
- [ ] Document fallback behavior

## Flutter Client Updates

### Note: Flutter client already prepared
The Flutter app has been architected to use the AI abstraction layer. No UI changes are required when the backend starts using real AI inference. The existing `ApiService` will automatically benefit from the improved backend predictions.

### Optional: Update Mock Data
- [ ] Consider updating mock disease data to match 39 classes
- [ ] Add crop-specific mock data
- [ ] Update severity mappings to match backend logic

## Validation

### Build Verification
- [ ] Run `python -m py_compile main.py` - no syntax errors
- [ ] Run `pip install -r requirements.txt` - no dependency issues
- [ ] Test FastAPI startup with model
- [ ] Test FastAPI startup without model (fallback)

### Runtime Verification
- [ ] Start FastAPI server
- [ ] Verify model loads successfully
- [ ] Verify Groq client initializes (if API key set)
- [ ] Test /analyze endpoint with real image
- [ ] Check logs for inference timing
- [ ] Verify offline mode works (fallback to mock)
- [ ] Test with various image formats

### Error Handling Verification
- [ ] Test with corrupted image file
- [ ] Test with non-image file
- [ ] Test with missing model file
- [ ] Test with corrupted model file
- [ ] Test without Groq API key
- [ ] Verify graceful fallback to mock data
- [ ] Verify user sees helpful error messages

## Final Checklist

Before enabling real AI inference in production:

- [ ] Model file placed in correct location
- [ ] All dependencies installed and tested
- [ ] Model loading tested
- [ ] Preprocessing tested
- [ ] Class name parsing tested
- [ ] Severity inference tested
- [ ] Anthropic API integrated and tested
- [ ] /analyze endpoint updated and tested
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] Performance targets met
- [ ] Build verification complete
- [ ] Runtime verification complete
- [ ] Error handling verified
- [ ] Documentation updated
- [ ] Environment variables configured
- [ ] Deployment tested
- [ ] Stakeholder approval obtained

## Quick Start

To enable real AI inference:

1. Place `model.tflite` in project root or `models/model.tflite`
2. Install dependencies: `pip install -r requirements.txt`
3. Set Groq API key (optional): `export GROQ_API_KEY=your_key`
4. Start server: `python main.py`
5. The /analyze endpoint will automatically use the real model

If model fails to load, the endpoint will fall back to mock data automatically.
+13
-10
Navigating.

