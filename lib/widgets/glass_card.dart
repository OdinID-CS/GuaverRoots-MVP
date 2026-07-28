import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../utils/device_performance.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final double opacity;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = UIConstants.radiusMedium,
    this.blurSigma = UIConstants.glassBlurSigma,
    this.opacity = UIConstants.glassOpacityLight,
    this.borderColor,
    this.shadows,
    this.onTap,
  });

  static PerformanceMode _currentMode = DevicePerformance.detect();

  static void refreshPerformanceMode() {
    _currentMode = DevicePerformance.detect();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = borderColor ??
        Colors.white.withValues(alpha: 0.18);

    final defaultShadows = <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ];

    final effectiveBlur = _currentMode.enableBlur ? blurSigma : _currentMode.blurSigma;
    final effectiveOpacity = _currentMode == PerformanceMode.low && opacity == UIConstants.glassOpacityLight
        ? UIConstants.glassOpacityDark
        : opacity;

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: effectiveOpacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: effectiveBorder,
              width: UIConstants.glassBorderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: shadows ?? defaultShadows,
          ),
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ?? defaultShadows,
      ),
      child: content,
    );
  }
}
