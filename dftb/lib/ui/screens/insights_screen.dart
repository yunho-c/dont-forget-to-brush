import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../data/mock_data.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insights',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.night800,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.night700),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Last 7 Days',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate200,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.slate400,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 160, child: _WeeklyChart()),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(
                child: _StatCard(
                  title: 'Consistency',
                  value: '85%',
                  subtitle: '+5% vs last week',
                  accent: AppColors.green500,
                  icon: Icons.trending_up,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Total Sessions',
                  value: '24',
                  subtitle: 'This month',
                  accent: AppColors.indigo500,
                  icon: Icons.stacked_bar_chart,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart();

  @override
  Widget build(BuildContext context) {
    final maxMinutes = mockWeeklyStats
        .map((stat) => stat.minutes)
        .fold<double>(0, (value, element) => element > value ? element : value);

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = constraints.maxHeight;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: mockWeeklyStats.map((stat) {
            final heightFactor = maxMinutes == 0
                ? 0.0
                : stat.minutes / maxMinutes;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: chartHeight * heightFactor,
                      decoration: BoxDecoration(
                        color: stat.completed
                            ? AppColors.indigo500
                            : AppColors.night700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stat.day,
                      style: const TextStyle(
                        color: AppColors.slate400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.night800,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.night700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(color: AppColors.slate400, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: accent, fontSize: 11)),
        ],
      ),
    );
  }
}
