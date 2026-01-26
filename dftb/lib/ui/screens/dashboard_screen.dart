import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_state_provider.dart';
import '../../theme/app_colors.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final settings = state.settings;
    final isBrushed = state.isBrushedTonight;
    final completedAt = settings.lastBrushTime != null
        ? DateTime.tryParse(settings.lastBrushTime!)
        : null;
    final displayName = settings.name.isEmpty ? 'Friend' : settings.name;

    return Stack(
      children: [
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 240,
          child: IgnorePointer(
            child: CustomPaint(painter: _BackgroundChartPainter()),
          ),
        ),
        CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _Header(name: displayName, streak: settings.streak),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _StatusRing(
                      isComplete: isBrushed,
                      bedtimeStart: settings.bedtimeStart,
                    ),
                    const SizedBox(height: 28),
                    if (!isBrushed)
                      _ActionGroup(
                        onBrushNow: state.openVerification,
                        onSleepToggle: state.toggleSleepMode,
                        isSleepModeActive: state.sleepModeActive,
                      )
                    else
                      _CompletionCard(completedAt: completedAt),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.streak});

  final String name;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good Evening,',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.slate400,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.night800.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.night700.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: 18,
                    color: AppColors.orange400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$streak',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'STREAK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate400,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusRing extends StatelessWidget {
  const _StatusRing({required this.isComplete, required this.bedtimeStart});

  final bool isComplete;
  final String bedtimeStart;

  @override
  Widget build(BuildContext context) {
    final borderColor = isComplete
        ? AppColors.green500.withValues(alpha: 0.35)
        : AppColors.indigo500.withValues(alpha: 0.35);
    final fillColor = isComplete
        ? AppColors.green500.withValues(alpha: 0.12)
        : AppColors.indigo500.withValues(alpha: 0.12);
    final glowColor = isComplete
        ? AppColors.green500.withValues(alpha: 0.2)
        : AppColors.indigo500.withValues(alpha: 0.25);
    final icon = isComplete ? Icons.star_rounded : Icons.nightlight_round;
    final iconColor = isComplete ? AppColors.emerald400 : AppColors.indigo500;
    final title = isComplete ? 'All Set' : 'Not yet';
    final subtitle = isComplete
        ? 'Sleep tight!'
        : 'Bedtime window starts at $bedtimeStart';

    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor,
        border: Border.all(color: borderColor, width: 4),
        boxShadow: [
          BoxShadow(color: glowColor, blurRadius: 60, spreadRadius: -16),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: iconColor),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.slate400, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionGroup extends StatelessWidget {
  const _ActionGroup({
    required this.onBrushNow,
    required this.onSleepToggle,
    required this.isSleepModeActive,
  });

  final VoidCallback onBrushNow;
  final VoidCallback onSleepToggle;
  final bool isSleepModeActive;

  @override
  Widget build(BuildContext context) {
    final sleepLabel = isSleepModeActive
        ? 'Sleep Mode Active'
        : 'Going to Sleep';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        children: [
          _GradientButton(label: 'Brush Now', onPressed: onBrushNow),
          const SizedBox(height: 12),
          _SecondaryButton(
            label: sleepLabel,
            icon: Icons.access_time_rounded,
            onPressed: onSleepToggle,
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [AppColors.indigo600, AppColors.indigo500],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.indigo500.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.night800,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.night700),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.slate300),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.slate300,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.completedAt});

  final DateTime? completedAt;

  @override
  Widget build(BuildContext context) {
    final timeLabel = completedAt == null
        ? 'earlier tonight'
        : _timeLabel(completedAt!);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.night800.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.night700.withValues(alpha: 0.6)),
        ),
        child: Text(
          'You completed your habit at $timeLabel.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.slate400, fontSize: 12),
        ),
      ),
    );
  }

  String _timeLabel(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _BackgroundChartPainter extends CustomPainter {
  const _BackgroundChartPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.indigo500.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final values = [0.2, 0.35, 0.28, 0.55, 0.45, 0.62, 0.52];
    final step = size.width / (values.length - 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = step * i;
      final y = size.height * (1 - values[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
