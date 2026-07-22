import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/scan_result.dart';
import '../core/constants/app_constants.dart';
import 'heatmap_screen.dart';

class TreatmentScreen extends StatelessWidget {
  final ScanResult scanResult;

  const TreatmentScreen({super.key, required this.scanResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Treatment'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (scanResult.isAreaScan)
            IconButton(
              icon: const Icon(Icons.map),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HeatmapScreen(scanResult: scanResult),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePreview(),
            const SizedBox(height: UIConstants.spacingLarge),
            _buildTimestampCard(),
            const SizedBox(height: UIConstants.spacingLarge),
            _buildDiseaseCard(),
            const SizedBox(height: UIConstants.spacingLarge),
            _buildDescriptionCard(),
            const SizedBox(height: UIConstants.spacingLarge),
            _buildConfidenceCard(),
            const SizedBox(height: UIConstants.spacingLarge),
            _buildSeverityCard(),
            const SizedBox(height: UIConstants.spacingLarge),
            _buildUrgencyCard(),
            const SizedBox(height: UIConstants.spacingLarge),
            _buildTreatmentCard(),
            const SizedBox(height: UIConstants.paddingXLarge),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Card(
      elevation: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
        child: Image.file(
          File(scanResult.imagePath),
          height: UIConstants.imagePreviewHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: UIConstants.imagePreviewHeight,
              color: Colors.grey[300],
              child: const Icon(Icons.image, size: UIConstants.iconXLarge, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimestampCard() {
    final dateFormatter = DateFormat(DateFormats.dateTimeDisplay);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.grey, size: UIConstants.iconMedium),
            const SizedBox(width: UIConstants.paddingMedium),
            Text(
              dateFormatter.format(scanResult.timestamp),
              style: TextStyle(
                fontSize: UIConstants.fontSizeMedium,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    if (scanResult.description == null || scanResult.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: UIConstants.iconMedium),
                SizedBox(width: UIConstants.spacingMedium),
                Text(
                  'About this Disease',
                  style: TextStyle(
                    fontSize: UIConstants.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.spacingMedium),
            Text(
              scanResult.description!,
              style: const TextStyle(fontSize: UIConstants.fontSizeMedium, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detected Disease',
              style: TextStyle(
                fontSize: UIConstants.fontSizeMedium,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: UIConstants.spacingMedium),
            Text(
              scanResult.diseaseName ?? 'Unknown',
              style: const TextStyle(
                fontSize: UIConstants.fontSizeXXLarge,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceCard() {
    final confidence = (scanResult.confidence ?? 0) * 100;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confidence',
              style: TextStyle(
                fontSize: UIConstants.fontSizeMedium,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: UIConstants.spacingMedium),
            LinearProgressIndicator(
              value: scanResult.confidence ?? 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                confidence > 80 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: UIConstants.spacingMedium),
            Text(
              '${confidence.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: UIConstants.fontSizeXLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityCard() {
    final severity = scanResult.severity ?? 'Unknown';
    Color severityColor;
    switch (severity.toLowerCase()) {
      case 'low':
        severityColor = Colors.green;
        break;
      case 'moderate':
        severityColor = Colors.orange;
        break;
      case 'high':
        severityColor = Colors.red;
        break;
      default:
        severityColor = Colors.grey;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Row(
          children: [
            Container(
              width: UIConstants.iconSmall,
              height: UIConstants.iconSmall,
              decoration: BoxDecoration(
                color: severityColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: UIConstants.paddingMedium),
            const Text(
              'Severity: ',
              style: TextStyle(fontSize: UIConstants.fontSizeLarge),
            ),
            Text(
              severity,
              style: TextStyle(
                fontSize: UIConstants.fontSizeXLarge,
                fontWeight: FontWeight.bold,
                color: severityColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencyCard() {
    return Card(
      elevation: 4,
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.orange, size: UIConstants.iconXLarge),
            const SizedBox(width: UIConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Urgency',
                    style: TextStyle(
                      fontSize: UIConstants.fontSizeMedium,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scanResult.urgency ?? 'Not specified',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.medical_services, color: Colors.green, size: UIConstants.iconMedium),
                SizedBox(width: UIConstants.spacingMedium),
                Text(
                  'Recommended Treatment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Text(
              scanResult.treatment ?? 'No treatment recommendation available',
              style: const TextStyle(fontSize: UIConstants.fontSizeLarge, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home),
            label: const Text('Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingLarge),
              textStyle: const TextStyle(fontSize: UIConstants.fontSizeLarge),
            ),
          ),
        ),
        const SizedBox(width: UIConstants.paddingMedium),
        if (scanResult.isAreaScan)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HeatmapScreen(scanResult: scanResult),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('View Heat Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingLarge),
                textStyle: const TextStyle(fontSize: UIConstants.fontSizeLarge),
              ),
            ),
          ),
      ],
    );
  }
}
