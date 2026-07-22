import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../services/storage_service.dart';
import '../models/scan_result.dart';
import '../core/constants/app_constants.dart';
import 'treatment_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Farm History'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showClearDialog(context),
          ),
        ],
      ),
      body: FutureBuilder<List<ScanResult>>(
        future: Future.value(StorageService.getAllScanResults()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          final scans = snapshot.data ?? [];

          if (scans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No scan history yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacingSmall),
                  Text(
                    'Start scanning to track your farm health',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          // Sort by timestamp descending
          scans.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scans.length,
            itemBuilder: (context, index) {
              return _buildScanCard(context, scans[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildScanCard(BuildContext context, ScanResult scan) {
    final dateFormatter = DateFormat(DateFormats.dateTimeDisplay);
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TreatmentScreen(scanResult: scan),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
                      child: const Icon(Icons.image, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (scan.isAreaScan)
                          const Icon(Icons.grid_on, size: UIConstants.iconSmall, color: Colors.blue),
                        const SizedBox(width: UIConstants.spacingSmall),
                        Expanded(
                          child: Text(
                            scan.diseaseName ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: UIConstants.fontSizeLarge,
                              fontWeight: FontWeight.bold,
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
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String? severity) {
    Color color;
    switch (severity?.toLowerCase()) {
      case 'low':
        color = Colors.green;
        break;
      case 'moderate':
        color = Colors.orange;
        break;
      case 'high':
        color = Colors.red;
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
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    final percentage = (confidence * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.paddingSmall, vertical: UIConstants.paddingSmall),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
      ),
      child: Text(
        '$percentage% conf.',
        style: const TextStyle(
          fontSize: UIConstants.fontSizeSmall,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
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
              await StorageService.clearAll();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
