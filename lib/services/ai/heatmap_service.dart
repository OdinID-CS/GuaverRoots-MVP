import 'package:flutter/material.dart';
import 'tiling_service.dart';

class HeatmapService {
 static Color getColorForScore(double score) {
   final t = score.clamp(0.0, 1.0);
   final alpha = (t * 255).round();
   return Color.fromARGB(alpha, 211, 47, 47); // red, transparent when healthy, solid when severe
 }

  /// Interpolates the points to find the color at any given (x, y) coordinate
  /// Using Inverse Distance Weighting (IDW) for smooth blending
  static Color getBlendedColor(double x, double y, List<HeatmapPoint> points) {
    if (points.isEmpty) return Colors.transparent;

    double totalWeight = 0;
    double weightedScore = 0;

    for (final point in points) {
      final distance = _calculateDistance(x, y, point.x, point.y);
      if (distance < 0.01) return getColorForScore(point.severityScore);

      // Weight is inverse of distance squared
      final weight = 1.0 / (distance * distance);
      totalWeight += weight;
      weightedScore += point.severityScore * weight;
    }

    if (totalWeight == 0) return Colors.transparent;
    return getColorForScore(weightedScore / totalWeight);
  }

  static double _calculateDistance(double x1, double y1, double x2, double y2) {
    final dx = x1 - x2;
    final dy = y1 - y2;
    return (dx * dx + dy * dy);
  }
}
