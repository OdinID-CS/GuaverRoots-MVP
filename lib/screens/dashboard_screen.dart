import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import 'scan_screen.dart';
import 'area_scan_screen.dart';
import 'history_screen.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                'Farm Dashboard',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            Consumer<HistoryProvider>(
              builder: (context, historyProvider, child) {
                return SliverPadding(
                  padding: const EdgeInsets.all(UIConstants.paddingXLarge),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildOverviewRow(historyProvider),
                      const SizedBox(height: UIConstants.paddingXLarge),
                      _buildRecentActivity(historyProvider),
                      const SizedBox(height: UIConstants.paddingXLarge),
                      _buildHealthScore(historyProvider),
                      const SizedBox(height: UIConstants.paddingXLarge),
                      _buildQuickActions(context),
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewRow(HistoryProvider historyProvider) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Scans',
            value: historyProvider.totalScans.toString(),
            icon: Icons.analytics,
            color: const Color(AppColors.forestGreen),
          ),
        ),
        const SizedBox(width: UIConstants.paddingLarge),
        Expanded(
          child: _StatCard(
            label: 'Diseased',
            value: historyProvider.diseasedScans.toString(),
            icon: Icons.warning,
            color: const Color(AppColors.redPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(HistoryProvider historyProvider) {
    final recent = historyProvider.mostRecentScan;
    return GlassCard(
      padding: const EdgeInsets.all(UIConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Most Recent Scan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(AppColors.forestGreen)),
          ),
          const SizedBox(height: UIConstants.spacingLarge),
          if (recent == null)
            Text(
              'No scans yet. Start by scanning your crops.',
              style: TextStyle(color: Colors.grey[600]),
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(AppColors.limeGreen).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                      ),
                      child: Icon(
                        recent.isAreaScan ? Icons.grid_on : Icons.camera_alt,
                        color: const Color(AppColors.forestGreen),
                      ),
                    ),
                    const SizedBox(width: UIConstants.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recent.diseaseName ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: UIConstants.fontSizeLarge,
                              fontWeight: FontWeight.w700,
                              color: Color(AppColors.forestGreen),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy • HH:mm').format(recent.timestamp),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHealthScore(HistoryProvider historyProvider) {
    final total = historyProvider.totalScans;
    final healthy = historyProvider.healthyScans;
    final avgConf = historyProvider.averageConfidence;
    
    double score = 0.0;
    if (total > 0) {
      score = (healthy / total) * 100;
    }

    Color scoreColor;
    String scoreLabel;
    if (score >= 80) {
      scoreColor = const Color(AppColors.forestGreen);
      scoreLabel = 'Good';
    } else if (score >= 50) {
      scoreColor = const Color(AppColors.orangePrimary);
      scoreLabel = 'Moderate';
    } else if (total > 0) {
      scoreColor = const Color(AppColors.redPrimary);
      scoreLabel = 'Poor';
    } else {
      scoreColor = Colors.grey;
      scoreLabel = 'N/A';
    }

    return GlassCard(
      padding: const EdgeInsets.all(UIConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Farm Health',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(AppColors.forestGreen)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  scoreLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: UIConstants.spacingLarge),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Avg Confidence',
                  value: total > 0 ? '${(avgConf * 100).toStringAsFixed(0)}%' : 'N/A',
                  color: const Color(AppColors.bluePrimary),
                ),
              ),
              const SizedBox(width: UIConstants.paddingLarge),
              Expanded(
                child: _MiniStat(
                  label: 'Healthy / Total',
                  value: total > 0 ? '$healthy / $total' : '0 / 0',
                  color: const Color(AppColors.forestGreen),
                ),
              ),
              const SizedBox(width: UIConstants.paddingLarge),
              Expanded(
                child: _MiniStat(
                  label: 'Most Common',
                  value: historyProvider.mostCommonDisease ?? 'N/A',
                  color: const Color(AppColors.orangePrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(AppColors.forestGreen)),
        ),
        const SizedBox(height: UIConstants.paddingLarge),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                label: 'New Scan',
                icon: Icons.camera_alt,
                color: const Color(AppColors.forestGreen),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: UIConstants.paddingLarge),
            Expanded(
              child: _ActionCard(
                label: 'Area Scan',
                icon: Icons.grid_on,
                color: const Color(AppColors.bluePrimary),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AreaScanScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: UIConstants.paddingLarge),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                label: 'History',
                icon: Icons.history,
                color: const Color(AppColors.orangePrimary),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: UIConstants.paddingLarge),
            Expanded(
              child: _ActionCard(
                label: 'Home',
                icon: Icons.home,
                color: Colors.purple,
                onTap: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(UIConstants.paddingLarge),
      child: Column(
        children: [
          Icon(icon, color: color, size: UIConstants.iconXLarge),
          const SizedBox(height: UIConstants.spacingMedium),
          Text(
            value,
            style: TextStyle(
              fontSize: UIConstants.fontSizeXXXLarge,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: UIConstants.spacingSmall),
          Text(
            label,
            style: TextStyle(
              fontSize: UIConstants.fontSizeSmall,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: UIConstants.fontSizeSmall,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: UIConstants.fontSizeLarge,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(UIConstants.paddingLarge),
      child: Column(
        children: [
          Icon(icon, color: color, size: UIConstants.iconLarge),
          const SizedBox(height: UIConstants.spacingMedium),
          Text(
            label,
            style: TextStyle(
              fontSize: UIConstants.fontSizeLarge,
              fontWeight: FontWeight.w700,
              color: const Color(AppColors.forestGreen),
            ),
          ),
        ],
      ),
    );
  }
}
