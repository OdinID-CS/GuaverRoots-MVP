import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_constants.dart';
import 'scan_screen.dart';
import 'area_scan_screen.dart';
import 'history_screen.dart';
import 'dashboard_screen.dart';
import '../services/weather_service.dart';
import '../models/weather_data.dart';
import '../widgets/glass_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
        child: SafeArea(
          child: SingleChildScrollView(
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
                const SizedBox(height: UIConstants.paddingXLarge),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GuaverRoots',
          style: GoogleFonts.poppins(
            fontSize: UIConstants.fontSizeXXXLarge,
            fontWeight: FontWeight.w800,
            color: const Color(AppColors.forestGreen),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: UIConstants.spacingSmall),
        Text(
          'Crop Health Assistant',
          style: GoogleFonts.poppins(
            fontSize: UIConstants.fontSizeXLarge,
            fontWeight: FontWeight.w500,
            color: const Color(AppColors.forestGreen).withValues(alpha: 0.75),
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
        riskColor = const Color(AppColors.forestGreen);
        riskLabel = 'Low Risk';
        riskIcon = Icons.check_circle;
        break;
      case DiseaseRisk.moderate:
        riskColor = const Color(AppColors.orangePrimary);
        riskLabel = 'Moderate Risk';
        riskIcon = Icons.warning;
        break;
      case DiseaseRisk.high:
        riskColor = const Color(AppColors.redPrimary);
        riskLabel = 'High Risk';
        riskIcon = Icons.dangerous;
        break;
    }

    return GlassCard(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      opacity: 0.55,
      borderColor: riskColor.withValues(alpha: 0.25),
      shadows: [
        BoxShadow(
          color: riskColor.withValues(alpha: 0.12),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
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
                  style: GoogleFonts.poppins(
                    fontSize: UIConstants.fontSizeMedium,
                    fontWeight: FontWeight.w700,
                    color: riskColor,
                  ),
                ),
                const SizedBox(height: UIConstants.spacingSmall),
                Text(
                  reason,
                  style: GoogleFonts.poppins(
                    fontSize: UIConstants.fontSizeSmall,
                    color: const Color(AppColors.forestGreen).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${weather.temperature.toInt()}°C',
            style: GoogleFonts.poppins(
              fontSize: UIConstants.fontSizeLarge,
              fontWeight: FontWeight.w700,
              color: const Color(AppColors.forestGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCardSkeleton() {
    return GlassCard(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      opacity: 0.5,
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
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: UIConstants.spacingSmall),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCardUnavailable() {
    return GlassCard(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      opacity: 0.5,
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
                  style: GoogleFonts.poppins(
                    fontSize: UIConstants.fontSizeMedium,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: UIConstants.spacingSmall),
                Text(
                  'Enable location services for disease risk assessment',
                  style: GoogleFonts.poppins(
                    fontSize: UIConstants.fontSizeSmall,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
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
          color: const Color(AppColors.forestGreen),
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
          color: const Color(AppColors.bluePrimary),
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
    return Column(
      children: [
        _buildBigButton(
          context,
          icon: Icons.history,
          label: 'Farm History',
          subtitle: 'View past scans and treatments',
          color: const Color(AppColors.orangePrimary),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
          },
        ),
        const SizedBox(height: UIConstants.paddingMedium),
        _buildBigButton(
          context,
          icon: Icons.dashboard,
          label: 'Farm Dashboard',
          subtitle: 'Health overview and statistics',
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          },
        ),
      ],
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
    return GlassCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      opacity: 0.65,
      borderColor: Colors.white.withValues(alpha: 0.35),
      shadows: [
        BoxShadow(
          color: color.withValues(alpha: 0.15),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.paddingMedium),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                    style: GoogleFonts.poppins(
                      fontSize: UIConstants.fontSizeXLarge,
                      fontWeight: FontWeight.w700,
                      color: const Color(AppColors.forestGreen),
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacingSmall),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: UIConstants.fontSizeMedium,
                      color: const Color(AppColors.forestGreen).withValues(alpha: 0.7),
                    ),
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

  Widget _buildFooter() {
    return Column(
      children: [
        Divider(color: Colors.grey[300], height: 1),
        const SizedBox(height: UIConstants.paddingMedium),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
           Icon(Icons.wifi_off, size: UIConstants.iconSmall, color: Colors.grey[600]),
            const SizedBox(width: UIConstants.spacingSmall),
            Text(
              'Works Offline',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
