import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'scan_screen.dart';
import 'area_scan_screen.dart';
import 'history_screen.dart';

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
