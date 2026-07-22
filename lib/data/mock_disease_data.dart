library mock_disease_data;

/// Mock disease data for offline demo mode
/// 
/// This file contains realistic sample disease data that is returned
/// when the API is unavailable or the device is offline.
/// Replace or extend this data as needed for your demo.

class MockDiseaseData {
  static final List<DiseaseSample> _diseases = [
    DiseaseSample(
      name: 'Leaf Rust',
      confidence: 0.87,
      severity: 'Moderate',
      urgency: 'Treat within 3-5 days',
      treatment: 'Apply fungicide spray containing chlorothalonil or mancozeb. Remove and destroy affected leaves. Ensure proper spacing between plants for better air circulation. Avoid overhead irrigation to reduce leaf wetness.',
      description: 'A fungal disease causing orange-brown pustules on leaves',
    ),
    DiseaseSample(
      name: 'Powdery Mildew',
      confidence: 0.92,
      severity: 'High',
      urgency: 'Treat immediately',
      treatment: 'Apply sulfur-based fungicide or neem oil spray. Remove heavily infected plant parts. Improve air circulation around plants. Reduce humidity by avoiding dense planting and watering at the base of plants.',
      description: 'White powdery coating on leaves and stems',
    ),
    DiseaseSample(
      name: 'Bacterial Leaf Spot',
      confidence: 0.78,
      severity: 'Moderate',
      urgency: 'Treat within 5-7 days',
      treatment: 'Apply copper-based fungicide. Remove infected leaves and plant debris. Avoid working with plants when wet. Use disease-free seeds and seedlings. Rotate crops to break disease cycles.',
      description: 'Water-soaked spots that turn brown with yellow halos',
    ),
    DiseaseSample(
      name: 'Early Blight',
      confidence: 0.85,
      severity: 'High',
      urgency: 'Treat within 2-3 days',
      treatment: 'Apply fungicides containing chlorothalonil or copper. Remove lower affected leaves. Mulch plants to prevent soil splash. Ensure proper plant spacing. Avoid overhead irrigation.',
      description: 'Dark concentric rings on lower leaves',
    ),
    DiseaseSample(
      name: 'Downy Mildew',
      confidence: 0.81,
      severity: 'High',
      urgency: 'Treat immediately',
      treatment: 'Apply fungicides with mefenoxam or copper. Remove infected plant material immediately. Improve drainage and reduce humidity. Space plants properly for air flow. Water early in the day.',
      description: 'Yellow patches on leaf tops with gray mold underneath',
    ),
    DiseaseSample(
      name: 'Anthracnose',
      confidence: 0.74,
      severity: 'Moderate',
      urgency: 'Treat within 4-6 days',
      treatment: 'Apply chlorothalonil or copper fungicides. Prune infected branches during dry weather. Avoid overhead irrigation. Remove and destroy fallen leaves and fruit. Disinfect tools between cuts.',
      description: 'Dark sunken lesions on leaves, stems, and fruit',
    ),
    DiseaseSample(
      name: 'Fusarium Wilt',
      confidence: 0.68,
      severity: 'High',
      urgency: 'Treat immediately',
      treatment: 'Remove infected plants entirely - do not compost. Solarize soil before replanting. Use resistant varieties. Rotate with non-host crops. Ensure proper drainage to prevent waterlogging.',
      description: 'Wilting and yellowing leaves despite adequate water',
    ),
    DiseaseSample(
      name: 'Healthy Plant',
      confidence: 0.95,
      severity: 'None',
      urgency: 'Continue monitoring',
      treatment: 'No treatment needed. Continue regular monitoring. Maintain proper watering, fertilization, and pest control practices. Consider preventive measures during high-risk weather conditions.',
      description: 'No disease detected - plant appears healthy',
    ),
  ];

  /// Get a random disease sample for single scan
  static DiseaseSample getRandomDisease() {
    return _diseases[(DateTime.now().millisecondsSinceEpoch) % _diseases.length];
  }

  /// Get disease samples for area scan (mixed results)
  static List<DiseaseSample> getAreaScanResults(int count) {
    final results = <DiseaseSample>[];
    for (int i = 0; i < count; i++) {
      results.add(_diseases[(DateTime.now().millisecondsSinceEpoch + i) % _diseases.length]);
    }
    return results;
  }

  /// Get a specific disease by name
  static DiseaseSample? getDiseaseByName(String name) {
    try {
      return _diseases.firstWhere((d) => d.name == name);
    } catch (e) {
      return null;
    }
  }
}

class DiseaseSample {
  final String name;
  final double confidence;
  final String severity;
  final String urgency;
  final String treatment;
  final String description;

  DiseaseSample({
    required this.name,
    required this.confidence,
    required this.severity,
    required this.urgency,
    required this.treatment,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'disease_name': name,
      'confidence': confidence,
      'severity': severity,
      'urgency': urgency,
      'treatment': treatment,
      'description': description,
    };
  }
}
