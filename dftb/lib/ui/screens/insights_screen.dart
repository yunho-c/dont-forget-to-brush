import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../../models/weekly_stat.dart';
import '../../state/app_state_provider.dart';
import '../../theme/app_colors.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(weeklyStatsProvider);
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
          shadcn.Card(
            padding: const EdgeInsets.all(20),
            borderRadius: BorderRadius.circular(24),
            borderColor: AppColors.night700,
            fillColor: AppColors.night800,
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
                SizedBox(
                  height: 160,
                  child: stats.when(
                    data: (items) => _WeeklyChart(stats: items),
                    loading: () => const Center(
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (_, __) => const Center(
                      child: Text(
                        'Unable to load insights.',
                        style: TextStyle(color: AppColors.slate400),
                      ),
                    ),
                  ),
                ),
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
  const _WeeklyChart({required this.stats});

  final List<WeeklyStat> stats;

  @override
  Widget build(BuildContext context) {
    final maxMinutes = stats
        .map((stat) => stat.minutes)
        .fold<double>(0, (value, element) => element > value ? element : value);

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = constraints.maxHeight;
        const labelBlockHeight = 18.0;
        final barMaxHeight = chartHeight > labelBlockHeight
            ? chartHeight - labelBlockHeight
            : 0.0;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: stats.map((stat) {
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
                      height: barMaxHeight * heightFactor,
                      decoration: BoxDecoration(
                        color: stat.completed
                            ? AppColors.indigo500
                            : AppColors.night700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    SizedBox(
                      height: labelBlockHeight,
                      child: Center(
                        child: Text(
                          stat.day,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                            color: AppColors.slate400,
                            fontSize: 11,
                          ),
                        ),
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
    return shadcn.Card(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      borderColor: AppColors.night700,
      fillColor: AppColors.night800,
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
