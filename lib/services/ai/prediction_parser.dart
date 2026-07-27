class PredictionParser {
  static Map<String, dynamic> parse(String rawLabel) {
    if (rawLabel == "Background_without_leaves") {
      return {
        'crop': 'None',
        'disease': 'Background',
        'isHealthy': false,
      };
    }

    final parts = rawLabel.split("___");
    if (parts.length < 2) {
      return {
        'crop': 'Unknown',
        'disease': rawLabel,
        'isHealthy': false,
      };
    }

    var crop = parts[0];
    final diseaseRaw = parts[1];

    // Check if healthy
    final isHealthy = diseaseRaw.toLowerCase().contains("healthy");

    // Clean up disease name (replace underscores with spaces)
    final disease = diseaseRaw.replaceAll("_", " ");

    // Handle special cases
    if (crop.contains("Pepper,_bell")) {
      crop = "Pepper (bell)";
    }

    return {
      'crop': crop,
      'disease': disease,
      'isHealthy': isHealthy,
    };
  }

  static String mapToSeverity(double confidence, bool isHealthy) {
    if (isHealthy) return "None";

    if (confidence > 0.8) {
      return "High";
    } else if (confidence > 0.6) {
      return "Moderate";
    } else {
      return "Low";
    }
  }
}
