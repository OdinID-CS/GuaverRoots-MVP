library prediction;

/// Model representing the output of AI disease prediction
class Prediction {
  /// The crop type detected (e.g., "tomato", "maize", "cassava")
  final String crop;
  
  /// The disease name detected (e.g., "Leaf Rust", "Healthy")
  final String disease;
  
  /// Confidence score from 0.0 to 1.0
  final double confidence;
  
  /// Severity level: "None", "Low", "Moderate", "High"
  final String severity;
  
  /// Optional ID for treatment recommendation lookup
  final String? recommendationId;

  Prediction({
    required this.crop,
    required this.disease,
    required this.confidence,
    required this.severity,
    this.recommendationId,
  });

  /// Create a Prediction from JSON
  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      crop: json['crop'] ?? 'unknown',
      disease: json['disease'] ?? 'unknown',
      confidence: (json['confidence'] as num).toDouble(),
      severity: json['severity'] ?? 'Unknown',
      recommendationId: json['recommendation_id'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'crop': crop,
      'disease': disease,
      'confidence': confidence,
      'severity': severity,
      'recommendation_id': recommendationId,
    };
  }

  /// Create a copy with optional field updates
  Prediction copyWith({
    String? crop,
    String? disease,
    double? confidence,
    String? severity,
    String? recommendationId,
  }) {
    return Prediction(
      crop: crop ?? this.crop,
      disease: disease ?? this.disease,
      confidence: confidence ?? this.confidence,
      severity: severity ?? this.severity,
      recommendationId: recommendationId ?? this.recommendationId,
    );
  }

  @override
  String toString() {
    return 'Prediction(crop: $crop, disease: $disease, confidence: ${(confidence * 100).toStringAsFixed(1)}%, severity: $severity)';
  }
}

/// Model for area scan predictions (multiple images)
class AreaPrediction {
  /// Individual predictions for each image
  final List<Prediction> predictions;
  
  /// Overall health assessment for the area
  final String overallHealth;
  
  /// Percentage of healthy area
  final double healthyPercentage;
  
  /// Percentage of area needing monitoring
  final double monitoringPercentage;
  
  /// Percentage of high-risk area
  final double highRiskPercentage;

  AreaPrediction({
    required this.predictions,
    required this.overallHealth,
    required this.healthyPercentage,
    required this.monitoringPercentage,
    required this.highRiskPercentage,
  });

  /// Create from list of predictions
  factory AreaPrediction.fromPredictions(List<Prediction> predictions) {
    int healthy = 0;
    int monitoring = 0;
    int highRisk = 0;

    for (final pred in predictions) {
      switch (pred.severity.toLowerCase()) {
        case 'none':
          healthy++;
          break;
        case 'low':
          monitoring++;
          break;
        case 'moderate':
          monitoring++;
          break;
        case 'high':
          highRisk++;
          break;
      }
    }

    final total = predictions.length;
    final healthyPct = total > 0 ? (healthy / total) * 100 : 0.0;
    final monitoringPct = total > 0 ? (monitoring / total) * 100 : 0.0;
    final highRiskPct = total > 0 ? (highRisk / total) * 100 : 0.0;

    String overallHealth;
    if (highRiskPct > 30) {
      overallHealth = 'Critical';
    } else if (highRiskPct > 10 || monitoringPct > 50) {
      overallHealth = 'Needs Attention';
    } else if (monitoringPct > 20) {
      overallHealth = 'Monitor';
    } else {
      overallHealth = 'Healthy';
    }

    return AreaPrediction(
      predictions: predictions,
      overallHealth: overallHealth,
      healthyPercentage: healthyPct,
      monitoringPercentage: monitoringPct,
      highRiskPercentage: highRiskPct,
    );
  }

  @override
  String toString() {
    return 'AreaPrediction(total: ${predictions.length}, health: $overallHealth, healthy: ${healthyPercentage.toStringAsFixed(1)}%, monitoring: ${monitoringPercentage.toStringAsFixed(1)}%, highRisk: ${highRiskPercentage.toStringAsFixed(1)}%)';
  }
}
