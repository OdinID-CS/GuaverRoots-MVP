import 'package:flutter/material.dart';
import 'dart:io';
import '../models/scan_result.dart';
import '../core/constants/app_constants.dart';

class HeatmapScreen extends StatelessWidget {
  final ScanResult scanResult;

  const HeatmapScreen({super.key, required this.scanResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Area Heat Map'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegend(),
            const SizedBox(height: UIConstants.paddingMedium),
            _buildHeatmapGrid(),
            const SizedBox(height: UIConstants.paddingLarge),
            _buildSummaryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Legend',
              style: TextStyle(
                fontSize: UIConstants.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            _buildLegendItem('Healthy', Colors.green),
            _buildLegendItem('Needs Monitoring', Colors.yellow),
            _buildLegendItem('High Risk', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: UIConstants.iconMedium,
            height: UIConstants.iconMedium,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: UIConstants.fontSizeMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    final images = scanResult.areaScanImages ?? [scanResult.imagePath];
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Farm Area Overview',
              style: TextStyle(
                fontSize: UIConstants.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: UIConstants.gridCrossAxisCount,
                crossAxisSpacing: UIConstants.gridCrossAxisSpacing,
                mainAxisSpacing: UIConstants.gridMainAxisSpacing,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final healthStatus = _getHealthStatus(index);
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                      child: Image.file(
                        File(images[index]),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                          border: Border.all(
                            color: healthStatus.color,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: UIConstants.paddingSmall,
                          vertical: UIConstants.paddingSmall,
                        ),
                        decoration: BoxDecoration(
                          color: healthStatus.color.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                        ),
                        child: Text(
                          healthStatus.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: UIConstants.fontSizeSmall,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final images = scanResult.areaScanImages ?? [scanResult.imagePath];
    int healthy = 0;
    int monitoring = 0;
    int highRisk = 0;

    for (int i = 0; i < images.length; i++) {
      final status = _getHealthStatus(i);
      if (status.label == 'Healthy') {
        healthy++;
      } else if (status.label == 'Monitor') {
        monitoring++;
      } else {
        highRisk++;
      }
    }

    return Card(
      elevation: 4,
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Area Summary',
              style: TextStyle(
                fontSize: UIConstants.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            _buildSummaryItem('Healthy Areas', healthy, Colors.green),
            _buildSummaryItem('Needs Monitoring', monitoring, Colors.yellow),
            _buildSummaryItem('High Risk Areas', highRisk, Colors.red),
            const SizedBox(height: UIConstants.paddingMedium),
            const Divider(),
            const SizedBox(height: UIConstants.paddingMedium),
            Text(
              'Total Scanned: ${images.length} locations',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ({String label, Color color}) _getHealthStatus(int index) {
    // Simulate health status based on index for demo
    // In real app, this would come from AI analysis
    final statuses = [
      (label: 'Healthy', color: Colors.green),
      (label: 'Monitor', color: Colors.yellow),
      (label: 'Risk', color: Colors.red),
    ];
    return statuses[index % statuses.length];
  }
}
