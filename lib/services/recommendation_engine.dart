import 'feedback_service.dart';

class RecommendationEngine {
  static String getRecommendation({
    required String disease,
    required String severity,
    String? crop,
    String? weatherRisk,
    FarmProfile? farmProfile,
  }) {
    final normalizedDisease = disease.trim().toLowerCase();
    final normalizedSeverity = severity.trim().toLowerCase();

    if (normalizedDisease == 'healthy' || normalizedDisease.contains('healthy')) {
      return _buildHealthyRecommendation(crop, weatherRisk);
    }

    final treatment = _getTreatmentForDisease(normalizedDisease, normalizedSeverity);
    final urgency = _getUrgency(normalizedSeverity);
    final preventive = _getPreventiveMeasures(normalizedDisease);
    final monitoring = _getMonitoringAdvice(normalizedSeverity, weatherRisk, farmProfile);

    return '$treatment\n\n$urgency\n\n$preventive\n\n$monitoring';
  }

  static String _buildHealthyRecommendation(String? crop, String? weatherRisk) {
    final cropText = crop != null ? 'Your $crop plants appear ' : 'Your crops appear ';
    final riskAdvice = weatherRisk != null
        ? '\n\nCurrent disease risk is $weatherRisk. Maintain good field hygiene to keep risk low.'
        : '';
    return '${cropText}healthy! Continue regular watering, fertilization, and scouting.\n\nMonitor weekly for early signs of stress or infection.$riskAdvice';
  }

  static String _getTreatmentForDisease(String disease, String severity) {
    if (disease.contains('rust')) {
      return severity == 'high' || severity == 'severe'
          ? 'Apply a fungicide containing propiconazole or tebuconazole immediately. Remove and destroy heavily infected leaves.'
          : 'Apply a protectant fungicide such as mancozeb. Remove infected leaves and ensure proper spacing for airflow.';
    }
    if (disease.contains('mildew')) {
      return severity == 'high' || severity == 'severe'
          ? 'Apply potash-based sprays or systemic fungicides like sulfur or myclobutanil. Prune dense canopies to improve airflow.'
          : 'Use neem oil or potassium bicarbonate sprays every 7-10 days. Improve air circulation by pruning affected areas.';
    }
    if (disease.contains('blight')) {
      return severity == 'high' || severity == 'severe'
          ? 'Apply a copper-based fungicide or chlorothalonil immediately. Remove all infected plant material and avoid overhead irrigation.'
          : 'Apply copper hydroxide or mancozeb preventively. Mulch around plants to prevent soil splash.';
    }
    if (disease.contains('spot')) {
      return severity == 'high' || severity == 'severe'
          ? 'Apply a systemic fungicide such as azoxystrobin. Remove heavily infected foliage and sterilize tools between plants.'
          : 'Apply copper or mancozeb sprays weekly. Water at the base of plants to keep leaves dry.';
    }
    if (disease.contains('wilt')) {
      return 'Remove and destroy infected plants immediately. Do not compost affected material. Rotate crops and improve soil drainage.';
    }
    if (disease.contains('mosaic') || disease.contains('virus')) {
      return 'No cure available. Remove and destroy infected plants immediately. Control aphid vectors with insecticidal soap or neem oil.';
    }
    if (disease.contains('rot')) {
      return severity == 'high' || severity == 'severe'
          ? 'Improve drainage immediately. Apply fungicide containing metalaxyl or copper. Remove rotted tissue.'
          : 'Reduce watering and improve drainage. Apply copper-based fungicide around the base.';
    }
    return 'Apply an appropriate fungicide or bactericide based on the specific diagnosis. Remove heavily infected parts and monitor daily.';
  }

  static String _getUrgency(String severity) {
    switch (severity) {
      case 'high':
      case 'severe':
        return 'Urgency: High - Treat within 24-48 hours to prevent spread.';
      case 'moderate':
        return 'Urgency: Moderate - Begin treatment within 3-5 days.';
      case 'low':
        return 'Urgency: Low - Monitor and treat within 1 week.';
      default:
        return 'Urgency: Routine - Apply treatment at your earliest convenience.';
    }
  }

  static String _getPreventiveMeasures(String disease) {
    if (disease.contains('rust') || disease.contains('blight')) {
      return 'Prevention: Water at the base, avoid overhead irrigation. Space plants adequately. Use resistant varieties next season.';
    }
    if (disease.contains('mildew')) {
      return 'Prevention: Avoid overcrowding. Water in the morning. Use disease-resistant varieties and ensure good air circulation.';
    }
    if (disease.contains('spot') || disease.contains('rot')) {
      return 'Prevention: Mulch to prevent soil splash. Sanitize tools. Rotate crops annually and avoid working in wet fields.';
    }
    return 'Prevention: Practice crop rotation, maintain field hygiene, and monitor plants regularly for early signs of disease.';
  }

  static String _getMonitoringAdvice(String severity, String? weatherRisk, FarmProfile? farmProfile) {
    String advice = 'Monitor: Check affected plants every 2-3 days. Take additional photos to track progression.';

    if (weatherRisk != null && (weatherRisk.contains('high') || weatherRisk.contains('High'))) {
      advice += '\n\nWeather alert: High disease risk conditions detected. Increase inspection frequency and consider preventive spraying.';
    }

    if (farmProfile != null && farmProfile.accuracy < 0.7 && farmProfile.totalScans > 3) {
      advice += '\n\nLocal note: Our previous predictions at this location had mixed results. Consider confirming with an extension officer.';
    }

    if (severity == 'high' || severity == 'severe') {
      advice += '\n\nFollow-up: Re-evaluate treatment effectiveness in 5-7 days. If condition worsens, consult an agricultural extension officer.';
    }

    return advice;
  }
}
