import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../../theme/app_colors.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return shadcn.SurfaceBlur(
      surfaceBlur: 16,
      child: Container(
        height: 80,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        decoration: BoxDecoration(
          color: AppColors.night900.withValues(alpha: 0.8),
          border: const Border(top: BorderSide(color: AppColors.night800)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                label: 'Tonight',
                icon: Icons.home_rounded,
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                label: 'Insights',
                icon: Icons.bar_chart_rounded,
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                label: 'Settings',
                icon: Icons.settings_rounded,
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor = isActive ? AppColors.indigo500 : AppColors.slate500;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
