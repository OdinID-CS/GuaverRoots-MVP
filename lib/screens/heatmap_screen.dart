import 'package:flutter/material.dart';
import 'dart:io';
import '../models/scan_result.dart';
import '../services/ai/tiling_service.dart';
import '../services/ai/heatmap_service.dart';
import '../core/constants/app_constants.dart';
import '../widgets/glass_card.dart';

class HeatmapScreen extends StatefulWidget {
  final ScanResult scanResult;

  const HeatmapScreen({super.key, required this.scanResult});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  double _overlayOpacity = 0.5;
  late List<HeatmapPoint> _points;

  @override
  void initState() {
    super.initState();
    _points = (widget.scanResult.heatmapPoints ?? [])
        .map((p) => HeatmapPoint.fromJson(p))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000000),
              Color(0xFF0A1F0A),
              Color(0xFF000000),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: Image.file(
                      File(widget.scanResult.imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                  Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Opacity(
                        opacity: _overlayOpacity,
                        child: CustomPaint(
                          painter: HeatmapPainter(points: _points),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildControls(),
            _buildSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return GlassCard(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      opacity: 0.65,
      margin: const EdgeInsets.all(UIConstants.paddingLarge),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Overlay Opacity', style: TextStyle(color: Colors.white)),
              Expanded(
                child: Slider(
                  value: _overlayOpacity,
                  onChanged: (val) => setState(() => _overlayOpacity = val),
                  activeColor: const Color(AppColors.limeGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendItem('Healthy', const Color(AppColors.bluePrimary)),
        _legendItem('Low', const Color(AppColors.forestGreen)),
        _legendItem('Mod', const Color(AppColors.orangePrimary)),
        _legendItem('High', const Color(AppColors.redPrimary)),
        _legendItem('Severe', Colors.redAccent),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }

  Widget _buildSummary() {
    final total = widget.scanResult.totalSections ?? 1;
    final infectedPercent = (widget.scanResult.diseasedSections ?? 0) / total * 100;

    return GlassCard(
      padding: const EdgeInsets.all(UIConstants.paddingLarge),
      opacity: 0.75,
      margin: const EdgeInsets.fromLTRB(UIConstants.paddingLarge, 0, UIConstants.paddingLarge, UIConstants.paddingLarge),
      borderRadius: UIConstants.radiusLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Area Health Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(AppColors.forestGreen))),
          const SizedBox(height: UIConstants.spacingLarge),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem('Infected Area', '${infectedPercent.toStringAsFixed(1)}%', const Color(AppColors.redPrimary)),
              _statItem('Avg Severity', widget.scanResult.severity ?? 'N/A', const Color(AppColors.orangePrimary)),
              _statItem('Confidence', '${((widget.scanResult.confidence ?? 0) * 100).toStringAsFixed(0)}%', const Color(AppColors.bluePrimary)),
            ],
          ),
          const SizedBox(height: UIConstants.spacingLarge),
          Text(
            'Primary Detection: ${widget.scanResult.diseaseName}',
            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(AppColors.forestGreen)),
          ),
          const SizedBox(height: 4),
          Text(
            widget.scanResult.recommendation ?? '',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class HeatmapPainter extends CustomPainter {
  final List<HeatmapPoint> points;

  HeatmapPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    const int resolution = 40;
    final dx = size.width / resolution;
    final dy = size.height / resolution;

    for (int i = 0; i < resolution; i++) {
      for (int j = 0; j < resolution; j++) {
        final x = (i + 0.5) * dx;
        final y = (j + 0.5) * dy;

        final normalizedX = x / size.width;
        final normalizedY = y / size.height;

        final color = HeatmapService.getBlendedColor(normalizedX, normalizedY, points);

        if (color != Colors.transparent) {
          paint.color = color.withValues(alpha: 0.6);
          canvas.drawRect(Rect.fromLTWH(i * dx, j * dy, dx, dy), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
