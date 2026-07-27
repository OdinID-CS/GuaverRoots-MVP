library app_constants;

/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'GuaverRoots';
  static const String appVersion = '1.0.0';
  
  // Storage
  static const String scanResultsBox = 'scan_results';
  
  // Area Scan
  static const int maxAreaPhotos = 9;
  
  // Image Compression
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  static const int jpegQuality = 85;
  
  // API
  static const int connectionTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 30;
  
  // Hive Type IDs (must be unique per type)
  static const int scanResultTypeId = 0;
  
  // Private constructor to prevent instantiation
  AppConstants._();
}

/// Severity levels for disease classification
class SeverityLevel {
  static const String low = 'Low';
  static const String moderate = 'Moderate';
  static const String high = 'High';
  static const String none = 'None';
  
  static List<String> get all => [low, moderate, high, none];
  
  SeverityLevel._();
}

/// UI-related constants
class UIConstants {
  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  
  // Elevation
  static const double elevationCard = 4.0;
  static const double elevationButton = 2.0;
  
  // Button Sizes
  static const double buttonHeight = 50.0;
  static const double buttonMinWidth = 120.0;
  
  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 64.0;
  
  // Font Sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 24.0;
  static const double fontSizeXXXLarge = 32.0;
  
  // Spacing
  static const double spacingSmall = 4.0;
  static const double spacingMedium = 8.0;
  static const double spacingLarge = 16.0;
  static const double spacingXLarge = 20.0;
  
  // Grid
  static const int gridCrossAxisCount = 3;
  static const double gridCrossAxisSpacing = 8.0;
  static const double gridMainAxisSpacing = 8.0;
  
  // Image Preview
  static const double imagePreviewHeight = 200.0;

  // Glassmorphism
  static const double glassBlurSigma = 12.0;
  static const double glassOpacityLight = 0.25;
  static const double glassOpacityDark = 0.45;
  static const double glassBorderWidth = 1.0;

  // Private constructor to prevent instantiation
  UIConstants._();
}

/// Color-related constants
class AppColors {
  static const int forestGreen = 0xFF1B5E20;
  static const int limeGreen = 0xFF76FF03;
  static const int greenPrimary = 0xFF2E7D32;
  static const int bluePrimary = 0xFF2196F3;
  static const int orangePrimary = 0xFFFF9800;
  static const int redPrimary = 0xFFF44336;
  static const int white = 0xFFFFFFFF;
  static const int black = 0xFF000000;

  // Private constructor to prevent instantiation
  AppColors._();
}

/// Date/Time format constants
class DateFormats {
  static const String dateTimeDisplay = 'MMM dd, yyyy • HH:mm';
  static const String dateDisplay = 'MMM dd, yyyy';
  static const String timeDisplay = 'HH:mm';
  static const String iso8601 = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
  
  // Private constructor to prevent instantiation
  DateFormats._();
}
