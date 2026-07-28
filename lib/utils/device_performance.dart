import 'dart:io';

enum PerformanceMode {
  high,
  medium,
  low;

  bool get isLowEnd => this == PerformanceMode.low;
  bool get supportsHeavyEffects => this == PerformanceMode.high;

  int get maxAreaPhotos {
    switch (this) {
      case PerformanceMode.high:
        return 9;
      case PerformanceMode.medium:
        return 6;
      case PerformanceMode.low:
        return 3;
    }
  }

  double get tileOverlap {
    switch (this) {
      case PerformanceMode.high:
        return 0.5;
      case PerformanceMode.medium:
        return 0.25;
      case PerformanceMode.low:
        return 0.0;
    }
  }

  int get tileBatchSize {
    switch (this) {
      case PerformanceMode.high:
        return 20;
      case PerformanceMode.medium:
        return 10;
      case PerformanceMode.low:
        return 5;
    }
  }

  bool get enableParticles => this != PerformanceMode.low;
  bool get enableBlur => this != PerformanceMode.low;
  double get blurSigma => this == PerformanceMode.low ? 6.0 : 12.0;
}

class DevicePerformance {
  static PerformanceMode detect() {
    try {
      final cores = Platform.numberOfProcessors;
      if (Platform.isAndroid || Platform.isIOS) {
        if (cores <= 4) {
          return PerformanceMode.low;
        } else if (cores <= 6) {
          return PerformanceMode.medium;
        }
      }
      if (cores <= 2) {
        return PerformanceMode.low;
      } else if (cores <= 4) {
        return PerformanceMode.medium;
      }
    } catch (_) {}

    return PerformanceMode.high;
  }
}
