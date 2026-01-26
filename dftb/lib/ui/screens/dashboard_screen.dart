import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../../state/app_state_scope.dart';
import '../../theme/app_colors.dart';
import '../data/mock_data.dart';
import '../widgets/app_buttons.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final settings = state.settings;
    final isBrushed = state.isBrushedTonight;
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatFullDate(DateTime.now());
    final quoteIndex = DateTime.now().day % motivationalQuotes.length;
    final quote = motivationalQuotes[quoteIndex];
    final completedAt = settings.lastBrushTime != null
        ? DateTime.tryParse(settings.lastBrushTime!)
        : null;
    final streakBadgeStyle =
        const shadcn.ButtonStyle.secondary(
          size: shadcn.ButtonSize.small,
          density: shadcn.ButtonDensity.dense,
        ).copyWith(
          decoration: (context, states, value) {
            if (value is BoxDecoration) {
              return value.copyWith(
                color: AppColors.orange400.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppColors.orange400.withValues(alpha: 0.3),
                ),
              );
            }
            return value;
          },
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tonight',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: AppColors.slate400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              shadcn.SecondaryBadge(
                style: streakBadgeStyle,
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: AppColors.orange400,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${settings.streak}',
                      style: const TextStyle(
                        color: AppColors.orange400,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _StatusCard(
            isBrushed: isBrushed,
            quote: quote,
            completedAt: completedAt,
            onPrimaryAction: state.openVerification,
          ),
          const SizedBox(height: 24),
          _BedtimeCard(
            isActive: state.sleepModeActive,
            onToggle: (_) => state.toggleSleepMode(),
          ),
          const SizedBox(height: 16),
          _ReminderCard(time: settings.bedtimeStart),
          const SizedBox(height: 16),
          if (settings.name.isNotEmpty)
            Text(
              'Good evening, ${settings.name}.',
              style: const TextStyle(color: AppColors.slate400, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.isBrushed,
    required this.quote,
    required this.completedAt,
    required this.onPrimaryAction,
  });

  final bool isBrushed;
  final String quote;
  final DateTime? completedAt;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final background = isBrushed
        ? AppColors.green500.withValues(alpha: 0.12)
        : AppColors.indigo500.withValues(alpha: 0.12);
    final border = isBrushed
        ? AppColors.green500.withValues(alpha: 0.4)
        : AppColors.indigo500.withValues(alpha: 0.4);
    final iconColor = isBrushed ? AppColors.green500 : AppColors.indigo500;

    return SizedBox(
      width: double.infinity,
      child: shadcn.Card(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(28),
        borderColor: border,
        fillColor: background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.night900,
                border: Border.all(color: border),
              ),
              child: Icon(
                isBrushed ? Icons.check_rounded : Icons.nightlight_round,
                color: iconColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isBrushed ? "You're all set!" : "Haven't brushed yet",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isBrushed ? 'Sleep tight. See you tomorrow.' : quote,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate400),
            ),
            const SizedBox(height: 20),
            if (!isBrushed)
              PrimaryButton(label: 'I Brushed', onPressed: onPrimaryAction)
            else
              shadcn.OutlineBadge(
                style:
                    const shadcn.ButtonStyle.outline(
                      size: shadcn.ButtonSize.small,
                      density: shadcn.ButtonDensity.dense,
                    ).copyWith(
                      decoration: (context, states, value) {
                        if (value is BoxDecoration) {
                          return value.copyWith(
                            border: Border.all(
                              color: AppColors.green500.withValues(alpha: 0.6),
                            ),
                          );
                        }
                        return value;
                      },
                    ),
                child: Text(
                  'Completed at ${_timeLabel(completedAt ?? DateTime.now())}',
                  style: const TextStyle(
                    color: AppColors.green500,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _timeLabel(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _BedtimeCard extends StatelessWidget {
  const _BedtimeCard({required this.isActive, required this.onToggle});

  final bool isActive;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return shadcn.Card(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      borderColor: AppColors.night700,
      fillColor: AppColors.night800,
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.indigo500.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bedtime, color: AppColors.indigo500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bedtime Mode',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? 'Watching for missed brushing.'
                      : 'Toggle when you are about to sleep.',
                  style: const TextStyle(
                    color: AppColors.slate400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          shadcn.Switch(
            value: isActive,
            onChanged: onToggle,
            activeColor: AppColors.indigo500,
            activeThumbColor: AppColors.slate200,
            inactiveColor: AppColors.night700,
            inactiveThumbColor: AppColors.slate400,
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return shadcn.Card(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      borderColor: AppColors.night700,
      fillColor: AppColors.night800.withValues(alpha: 0.7),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppColors.night700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                '22',
                style: TextStyle(
                  color: AppColors.slate400,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scheduled Reminder',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(time),
                  style: const TextStyle(
                    color: AppColors.slate400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.slate400),
        ],
      ),
    );
  }

  String _formatTime(String raw) {
    final parts = raw.split(':');
    if (parts.length != 2) return raw;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return raw;
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }
}
