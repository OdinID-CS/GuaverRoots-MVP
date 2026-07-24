import 'package:flutter/material.dart';
import 'dart:io';
import '../models/scan_result.dart';
import '../core/constants/app_constants.dart';
import 'treatment_screen.dart';

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
            _buildHeatmapGrid(context),
            const SizedBox(height: UIConstants.paddingLarge),
            _buildSummaryCard(),
            if (scanResult.overallSummary != null) ...[
              const SizedBox(height: UIConstants.paddingMedium),
              _buildOverallSummaryCard(),
            ],
            if (scanResult.recommendation != null) ...[
              const SizedBox(height: UIConstants.paddingMedium),
              _buildRecommendationCard(),
            ],
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

  Widget _buildHeatmapGrid(BuildContext context) {
    final images = scanResult.areaScanImages ?? [scanResult.imagePath];
    final results = scanResult.areaScanResults;
    
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
                final healthStatus = _getHealthStatus(index, results);
                return GestureDetector(
                  onTap: () => _showSectionDetails(context, index, results),
                  child: Stack(
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
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: UIConstants.paddingSmall,
                            vertical: UIConstants.paddingSmall,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: UIConstants.fontSizeSmall,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
    final results = scanResult.areaScanResults;
    
    // Use actual counts from backend if available, otherwise calculate from results
    int healthy = scanResult.healthySections ?? 0;
    int monitoring = 0;
    int highRisk = 0;

    if (results != null) {
      for (var result in results) {
        final status = _getHealthStatusFromResult(result);
        if (status.label == 'Monitor') {
          monitoring++;
        } else if (status.label == 'Risk') {
          highRisk++;
        }
      }
    } else {
      // Fallback to simulated data
      for (int i = 0; i < images.length; i++) {
        final status = _getHealthStatus(i, null);
        if (status.label == 'Healthy') {
          healthy++;
        } else if (status.label == 'Monitor') {
          monitoring++;
        } else {
          highRisk++;
        }
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
              'Total Scanned: ${scanResult.totalSections ?? images.length} locations',
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

  ({String label, Color color}) _getHealthStatus(int index, List<dynamic>? results) {
    // Use actual results from backend if available
    if (results != null && index < results.length) {
      return _getHealthStatusFromResult(results[index]);
    }
    
    // Fallback to simulated data for demo
    final statuses = [
      (label: 'Healthy', color: Colors.green),
      (label: 'Monitor', color: Colors.yellow),
      (label: 'Risk', color: Colors.red),
    ];
    return statuses[index % statuses.length];
  }

  ({String label, Color color}) _getHealthStatusFromResult(dynamic result) {
    final severity = result['severity']?.toString().toLowerCase() ?? 'low';
    final isHealthy = result['is_healthy'] ?? false;
    
    if (isHealthy || severity == 'none' || severity == 'low') {
      return (label: 'Healthy', color: Colors.green);
    } else if (severity == 'moderate') {
      return (label: 'Monitor', color: Colors.yellow);
    } else {
      return (label: 'Risk', color: Colors.red);
    }
  }

  void _showSectionDetails(BuildContext context, int index, List<dynamic>? results) {
    if (results != null && index < results.length) {
      final result = results[index];
      final sectionResult = ScanResult(
        id: result['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: scanResult.areaScanImages?[index] ?? scanResult.imagePath,
        timestamp: DateTime.now(),
        diseaseName: result['disease_name']?.toString(),
        confidence: result['confidence']?.toDouble(),
        severity: result['severity']?.toString(),
        treatment: result['treatment']?.toString(),
        urgency: result['urgency']?.toString(),
        description: result['description']?.toString(),
        isAreaScan: false,
        notes: result['notes']?.toString(),
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TreatmentScreen(scanResult: sectionResult),
        ),
      );
    }
  }

  Widget _buildOverallSummaryCard() {
    return Card(
      elevation: 4,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'Overall Summary',
                  style: TextStyle(
                    fontSize: UIConstants.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Text(
              scanResult.overallSummary ?? 'No summary available',
              style: const TextStyle(fontSize: UIConstants.fontSizeMedium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return Card(
      elevation: 4,
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text(
                  'Recommendation',
                  style: TextStyle(
                    fontSize: UIConstants.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Text(
              scanResult.recommendation ?? 'No recommendation available',
              style: const TextStyle(fontSize: UIConstants.fontSizeMedium),
            ),
          ],
        ),
      ),
    );
  }
}
