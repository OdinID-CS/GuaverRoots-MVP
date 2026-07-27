import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/scan_result.dart';
import '../core/constants/app_constants.dart';
import 'treatment_screen.dart';
import 'heatmap_screen.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F5E9),
              Color(0xFFF1F8E9),
              Color(0xFFFAFFFA),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: const Color(AppColors.forestGreen),
              title: const Text(
                'Farm History',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              actions: [
                Consumer<HistoryProvider>(
                  builder: (context, historyProvider, child) {
                    final hasHistory = historyProvider.scanHistory.isNotEmpty;
                    return IconButton(
                      icon: Icon(Icons.delete_outline, color: hasHistory ? Colors.white : Colors.white54),
                      onPressed: hasHistory ? () => _showClearDialog(context) : null,
                    );
                  },
                ),
              ],
            ),
            Consumer<HistoryProvider>(
              builder: (context, historyProvider, child) {
                final scans = historyProvider.scanHistory;

                if (scans.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(AppColors.forestGreen).withValues(alpha: 0.08),
                            ),
                            child: Icon(Icons.history, size: 64, color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No scan history yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start scanning to track your farm health',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(UIConstants.paddingLarge),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildScanCard(context, scans[index]);
                      },
                      childCount: scans.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanCard(BuildContext context, ScanResult scan) {
    final dateFormatter = DateFormat(DateFormats.dateTimeDisplay);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.paddingLarge),
      child: GlassCard(
        onTap: () {
          if (scan.isAreaScan && scan.areaScanResults != null && scan.areaScanResults!.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HeatmapScreen(scanResult: scan),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TreatmentScreen(scanResult: scan),
              ),
            );
          }
        },
        opacity: 0.75,
        borderColor: Colors.white.withValues(alpha: 0.4),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
              child: Image.file(
                File(scan.imagePath),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: UIConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (scan.isAreaScan)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(AppColors.bluePrimary).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.grid_on, size: UIConstants.iconSmall, color: const Color(AppColors.bluePrimary)),
                        ),
                      if (scan.isAreaScan) const SizedBox(width: UIConstants.spacingSmall),
                      Expanded(
                        child: Text(
                          scan.diseaseName ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: UIConstants.fontSizeLarge,
                            fontWeight: FontWeight.w700,
                            color: Color(AppColors.forestGreen),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormatter.format(scan.timestamp),
                    style: TextStyle(
                      fontSize: UIConstants.fontSizeSmall,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacingSmall),
                  Row(
                    children: [
                      _buildSeverityBadge(scan.severity),
                      const SizedBox(width: UIConstants.spacingSmall),
                      if (scan.confidence != null)
                        _buildConfidenceBadge(scan.confidence!),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String? severity) {
    Color color;
    switch (severity?.toLowerCase()) {
      case 'low':
        color = const Color(AppColors.forestGreen);
        break;
      case 'moderate':
        color = const Color(AppColors.orangePrimary);
        break;
      case 'high':
        color = const Color(AppColors.redPrimary);
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.paddingSmall, vertical: UIConstants.paddingSmall),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
      ),
      child: Text(
        severity ?? 'Unknown',
        style: TextStyle(
          fontSize: UIConstants.fontSizeSmall,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    final percentage = (confidence * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.paddingSmall, vertical: UIConstants.paddingSmall),
      decoration: BoxDecoration(
        color: const Color(AppColors.bluePrimary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
      ),
      child: Text(
        '$percentage% conf.',
        style: const TextStyle(
          fontSize: UIConstants.fontSizeSmall,
          color: Color(AppColors.bluePrimary),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to delete all scan history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final historyProvider = context.read<HistoryProvider>();
              await historyProvider.clearAll();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: const Color(AppColors.redPrimary)),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
