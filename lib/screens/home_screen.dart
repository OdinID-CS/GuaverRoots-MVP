import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'scan_screen.dart';
import 'area_scan_screen.dart';
import 'history_screen.dart';
import '../services/weather_service.dart';
import '../models/weather_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.paddingXLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: UIConstants.paddingXLarge),
              _buildWeatherRiskCard(),
              const SizedBox(height: UIConstants.paddingMedium),
              _buildMainActions(context),
              const SizedBox(height: UIConstants.paddingLarge),
              _buildSecondaryActions(context),
              const Spacer(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GuaverRoots',
          style: TextStyle(
            fontSize: UIConstants.fontSizeXXXLarge,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: UIConstants.spacingSmall),
        Text(
          'Crop Health Assistant',
          style: TextStyle(
            fontSize: UIConstants.fontSizeXLarge,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherRiskCard() {
    return FutureBuilder<WeatherData?>(
      future: WeatherService.getCurrentWeather(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildRiskCardSkeleton();
        }

        final weather = snapshot.data;
        if (weather == null) {
          return _buildRiskCardUnavailable();
        }

        final risk = WeatherService.calculateDiseaseRisk(weather);
        final reason = WeatherService.getRiskReason(risk, weather);

        return _buildRiskCard(risk, reason, weather);
      },
    );
  }

  Widget _buildRiskCard(DiseaseRisk risk, String reason, WeatherData weather) {
    Color riskColor;
    String riskLabel;
    IconData riskIcon;

    switch (risk) {
      case DiseaseRisk.low:
        riskColor = Colors.green;
        riskLabel = 'Low Risk';
        riskIcon = Icons.check_circle;
        break;
      case DiseaseRisk.moderate:
        riskColor = Colors.orange;
        riskLabel = 'Moderate Risk';
        riskIcon = Icons.warning;
        break;
      case DiseaseRisk.high:
        riskColor = Colors.red;
        riskLabel = 'High Risk';
        riskIcon = Icons.dangerous;
        break;
    }

    return Card(
      elevation: 4,
      color: riskColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.paddingSmall),
              decoration: BoxDecoration(
                color: riskColor,
                borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
              ),
              child: Icon(riskIcon, color: Colors.white, size: UIConstants.iconMedium),
            ),
            const SizedBox(width: UIConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Disease Risk: $riskLabel',
                    style: TextStyle(
                      fontSize: UIConstants.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacingSmall),
                  Text(
                    reason,
                    style: TextStyle(
                      fontSize: UIConstants.fontSizeSmall,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${weather.temperature.toInt()}°C',
              style: TextStyle(
                fontSize: UIConstants.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCardSkeleton() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Row(
          children: [
            Container(
              width: UIConstants.iconMedium,
              height: UIConstants.iconMedium,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
              ),
            ),
            const SizedBox(width: UIConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: UIConstants.spacingSmall),
                  Container(
                    width: double.infinity,
                    height: 12,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCardUnavailable() {
    return Card(
      elevation: 4,
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.grey[600], size: UIConstants.iconMedium),
            const SizedBox(width: UIConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weather data unavailable',
                    style: TextStyle(
                      fontSize: UIConstants.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacingSmall),
                  Text(
                    'Enable location services for disease risk assessment',
                    style: TextStyle(
                      fontSize: UIConstants.fontSizeSmall,
                      color: Colors.grey[500],
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

  Widget _buildMainActions(BuildContext context) {
    return Column(
      children: [
        _buildBigButton(
          context,
          icon: Icons.camera_alt,
          label: 'Scan Crop',
          subtitle: 'Take a photo for analysis',
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScanScreen()),
            );
          },
        ),
        const SizedBox(height: UIConstants.paddingMedium),
        _buildBigButton(
          context,
          icon: Icons.grid_on,
          label: 'Area Scan',
          subtitle: 'Multiple photos for field view',
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AreaScanScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
    return _buildBigButton(
      context,
      icon: Icons.history,
      label: 'Farm History',
      subtitle: 'View past scans and treatments',
      color: Colors.orange,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HistoryScreen()),
        );
      },
    );
  }

  Widget _buildBigButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.paddingMedium),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(UIConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                ),
                child: Icon(icon, size: UIConstants.iconLarge, color: Colors.white),
              ),
              const SizedBox(width: UIConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: UIConstants.fontSizeXLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: UIConstants.spacingSmall),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeMedium,
                        color: Colors.grey[600],
                      ),
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

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: UIConstants.paddingMedium),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: UIConstants.iconSmall, color: Colors.grey[600]),
            const SizedBox(width: UIConstants.spacingSmall),
            Text(
              'Works Offline',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
