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
  late final List<_ImagePageData> _pages;
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pages = _buildPages();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_ImagePageData> _buildPages() {
    final perImage = widget.scanResult.areaScanResults;

    // Area scan with per-image results: one page per photo, each with its own heatmap
    if (widget.scanResult.isAreaScan && perImage != null && perImage.isNotEmpty) {
      return perImage.map((entry) {
        final map = entry as Map;
        final rawPoints = (map['heatmapPoints'] as List?) ?? [];
        final points = rawPoints
            .map((p) => HeatmapPoint.fromJson(Map<String, dynamic>.from(p as Map)))
            .toList();
        return _ImagePageData(
          imagePath: map['imagePath'] as String,
          points: points,
          diseaseName: map['diseaseName'] as String?,
          confidence: (map['confidence'] as num?)?.toDouble(),
          severity: map['severity'] as String?,
        );
      }).toList();
    }

    // Fallback: single scan, or area scan without per-image data (older saved scans)
    final points = (widget.scanResult.heatmapPoints ?? [])
        .map((p) => HeatmapPoint.fromJson(p))
        .toList();
    return [
      _ImagePageData(
        imagePath: widget.scanResult.imagePath,
        points: points,
        diseaseName: widget.scanResult.diseaseName,
        confidence: widget.scanResult.confidence,
        severity: widget.scanResult.severity,
      ),
    ];
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
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Stack(
                        children: [
                          Center(
                            child: Image.file(
                              File(page.imagePath),
                              fit: BoxFit.contain,
                            ),
                          ),
                          Center(
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: Opacity(
                                opacity: _overlayOpacity,
                                child: CustomPaint(
                                  painter: HeatmapPainter(points: page.points),
                                  size: Size.infinite,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (_pages.length > 1)
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Image ${_currentPage + 1} of ${_pages.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  if (_pages.length > 1)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          final active = i == _currentPage;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 10 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(AppColors.limeGreen)
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
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
          Text(
            _pages.length > 1 ? 'Overall Area Health Summary' : 'Area Health Summary',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(AppColors.forestGreen)),
          ),
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
            widget.scanResult.overallSummary ?? widget.scanResult.recommendation ?? '',
            style: TextStyle(color: Colors.grey[700]),
          ),
          if (widget.scanResult.recommendation != null && widget.scanResult.overallSummary != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.scanResult.recommendation!,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
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

class _ImagePageData {
  final String imagePath;
  final List<HeatmapPoint> points;
  final String? diseaseName;
  final double? confidence;
  final String? severity;

  _ImagePageData({
    required this.imagePath,
    required this.points,
    this.diseaseName,
    this.confidence,
    this.severity,
  });
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

        if (color.a > 0) {
          paint.color = color;
          canvas.drawRect(Rect.fromLTWH(i * dx, j * dy, dx, dy), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}