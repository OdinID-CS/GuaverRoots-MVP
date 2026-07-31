import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/scan_result.dart';
import '../models/weather_data.dart';
import '../core/constants/app_constants.dart';
import '../services/recommendation_engine.dart';
import '../services/notification_service.dart';
import '../services/weather_service.dart';
import 'heatmap_screen.dart';
import '../widgets/glass_card.dart';
import '../widgets/feedback_dialog.dart';

class TreatmentScreen extends StatefulWidget {
  final ScanResult scanResult;

  const TreatmentScreen({super.key, required this.scanResult});

  @override
  State<TreatmentScreen> createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends State<TreatmentScreen> {
  @override
  Widget build(BuildContext context) {
    final scanResult = widget.scanResult;
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
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: const Color(AppColors.forestGreen),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  scanResult.diseaseName ?? 'Treatment',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(AppColors.forestGreen),
                        Color(0xFF2E7D32),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    size: 80,
                    color: Color(AppColors.limeGreen),
                  ),
                ),
              ),
              actions: [
                if (scanResult.isAreaScan)
                  IconButton(
                    icon: const Icon(Icons.map, color: Colors.white),
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(UIConstants.paddingXLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePreview(scanResult),
                    const SizedBox(height: UIConstants.spacingLarge),
                    _buildTimestampCard(scanResult),
                    const SizedBox(height: UIConstants.spacingLarge),
                    _buildDiseaseCard(scanResult),
                    const SizedBox(height: UIConstants.spacingLarge),
                    if (scanResult.description != null && scanResult.description!.isNotEmpty) ...[
                      _buildDescriptionCard(scanResult),
                      const SizedBox(height: UIConstants.spacingLarge),
                    ],
                    _buildConfidenceCard(scanResult),
                    const SizedBox(height: UIConstants.spacingLarge),
                    _buildSeverityCard(scanResult),
                    const SizedBox(height: UIConstants.spacingXLarge),
                    _buildRecommendationCard(scanResult),
                    const SizedBox(height: UIConstants.spacingLarge),
                    _buildReminderButton(scanResult),
                    const SizedBox(height: UIConstants.spacingLarge),
                    _buildLocationCard(scanResult),
                    const SizedBox(height: UIConstants.spacingLarge),
                    _buildActionButtons(context, scanResult),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(ScanResult scanResult) {
    return GlassCard(
      padding: EdgeInsets.zero,
      opacity: 0.7,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        child: Image.file(
          File(scanResult.imagePath),
          height: UIConstants.imagePreviewHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: UIConstants.imagePreviewHeight,
              color: Colors.grey[300],
              child: Icon(Icons.image, size: UIConstants.iconXLarge, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimestampCard(ScanResult scanResult) {
    final dateFormatter = DateFormat(DateFormats.dateTimeDisplay);
    return GlassCard(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(AppColors.forestGreen).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
            ),
            child: const Icon(Icons.access_time, color: Color(AppColors.forestGreen), size: UIConstants.iconMedium),
          ),
          const SizedBox(width: UIConstants.paddingMedium),
          Text(
            dateFormatter.format(scanResult.timestamp),
            style: TextStyle(
              fontSize: UIConstants.fontSizeMedium,
              color: const Color(AppColors.forestGreen).withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(ScanResult scanResult) {
    return GlassCard(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      opacity: 0.6,
      borderColor: const Color(AppColors.bluePrimary).withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(AppColors.bluePrimary), size: UIConstants.iconMedium),
              const SizedBox(width: UIConstants.spacingMedium),
              Text(
                'About this Disease',
                style: TextStyle(
                  fontSize: UIConstants.fontSizeMedium,
                  fontWeight: FontWeight.w700,
                  color: const Color(AppColors.bluePrimary),
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
    );
  }

  Widget _buildDiseaseCard(ScanResult scanResult) {
    return GlassCard(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detected Disease',
            style: TextStyle(
              fontSize: UIConstants.fontSizeMedium,
              color: const Color(AppColors.forestGreen).withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: UIConstants.spacingMedium),
          Text(
            scanResult.diseaseName ?? 'Unknown',
            style: const TextStyle(
              fontSize: UIConstants.fontSizeXXLarge,
              fontWeight: FontWeight.w800,
              color: Color(AppColors.forestGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceCard(ScanResult scanResult) {
    final confidence = (scanResult.confidence ?? 0) * 100;
    return GlassCard(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confidence',
            style: TextStyle(
              fontSize: UIConstants.fontSizeMedium,
              color: const Color(AppColors.forestGreen).withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: UIConstants.spacingMedium),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: scanResult.confidence ?? 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                confidence > 80 ? const Color(AppColors.forestGreen) : const Color(AppColors.orangePrimary),
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: UIConstants.spacingMedium),
          Text(
            '${confidence.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: UIConstants.fontSizeXLarge,
              fontWeight: FontWeight.w800,
              color: Color(AppColors.forestGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityCard(ScanResult scanResult) {
    final severity = scanResult.severity ?? 'Unknown';
    Color severityColor;
    switch (severity.toLowerCase()) {
      case 'low':
        severityColor = const Color(AppColors.forestGreen);
        break;
      case 'moderate':
        severityColor = const Color(AppColors.orangePrimary);
        break;
      case 'high':
        severityColor = const Color(AppColors.redPrimary);
        break;
      default:
        severityColor = Colors.grey;
    }

    return GlassCard(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      child: Row(
        children: [
          Container(
            width: UIConstants.iconSmall,
            height: UIConstants.iconSmall,
            decoration: BoxDecoration(
              color: severityColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: severityColor.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: UIConstants.paddingMedium),
          Text(
            'Severity: ',
            style: TextStyle(fontSize: UIConstants.fontSizeLarge, color: Colors.grey[700]),
          ),
          Text(
            severity,
            style: TextStyle(
              fontSize: UIConstants.fontSizeXLarge,
              fontWeight: FontWeight.w800,
              color: severityColor,
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildRecommendationCard(ScanResult scanResult) {
     return FutureBuilder<WeatherData?>(
       future: WeatherService.getCurrentWeather(),
       builder: (context, snapshot) {
         final severity = scanResult.severity ?? 'low';
         final disease = scanResult.diseaseName ?? 'healthy';

         String? weatherRisk;
         final weather = snapshot.data;
         if (weather != null) {
           final risk = WeatherService.calculateDiseaseRisk(weather);
           weatherRisk = risk.name;
         }

         final recommendation = RecommendationEngine.getRecommendation(
           disease: disease,
           severity: severity,
           crop: scanResult.notes?.replaceAll('Crop: ', ''),
           weatherRisk: weatherRisk,
         );

         return GlassCard(
           padding: const EdgeInsets.all(UIConstants.paddingMedium),
           opacity: 0.75,
           borderColor: const Color(AppColors.limeGreen).withValues(alpha: 0.2),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 children: [
                   const Icon(Icons.lightbulb, color: Color(AppColors.forestGreen), size: UIConstants.iconMedium),
                   const SizedBox(width: UIConstants.spacingMedium),
                   Text(
                     'Recommended Treatment',
                     style: TextStyle(
                       fontSize: 16,
                       fontWeight: FontWeight.w700,
                       color: const Color(AppColors.forestGreen),
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: UIConstants.paddingMedium),
               Text(
                 recommendation,
                 style: const TextStyle(fontSize: UIConstants.fontSizeMedium, height: 1.6),
               ),
             ],
           ),
         );
       },
     );
   }
  Widget _buildReminderButton(ScanResult scanResult) {
    return ElevatedButton.icon(
      onPressed: () async {
        final notificationService = NotificationService();
        final scheduledDate = DateTime.now().add(const Duration(days: 2));
        await notificationService.scheduleTreatmentReminder(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Treatment Reminder: ${scanResult.diseaseName ?? 'crop'}',
          body: 'Follow up on your treatment plan. Check your crops for improvement.',
          scheduledDate: scheduledDate,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reminder set for ${DateFormat('MMM dd, yyyy').format(scheduledDate)}'),
              backgroundColor: const Color(AppColors.forestGreen),
            ),
          );
        }
      },
      icon: const Icon(Icons.notifications_active, color: Colors.white),
      label: const Text('Set Treatment Reminder'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(AppColors.forestGreen),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingLarge),
        textStyle: const TextStyle(fontSize: UIConstants.fontSizeLarge),
      ),
    );
  }

  Widget _buildLocationCard(ScanResult scanResult) {
    final location = scanResult.location;
    if (location == null || location.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      opacity: 0.6,
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(AppColors.forestGreen), size: UIConstants.iconMedium),
          const SizedBox(width: UIConstants.paddingMedium),
          Text(
            location,
            style: TextStyle(
              fontSize: UIConstants.fontSizeMedium,
              color: const Color(AppColors.forestGreen).withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ScanResult scanResult) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home),
                label: const Text('Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppColors.forestGreen),
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
                    backgroundColor: const Color(AppColors.bluePrimary),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingLarge),
                    textStyle: const TextStyle(fontSize: UIConstants.fontSizeLarge),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: UIConstants.paddingMedium),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => FeedbackDialog(scanResult: scanResult),
              );
            },
            icon: const Icon(Icons.feedback, color: Colors.white),
            label: const Text('Feedback'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppColors.orangePrimary),
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