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
      surfaceBlur: 18,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        decoration: BoxDecoration(
          color: AppColors.night900.withValues(alpha: 0.9),
          border: const Border(top: BorderSide(color: AppColors.night700)),
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
    return SizedBox(
      width: 72,
      child: shadcn.SelectedButton(
        value: isActive,
        onChanged: (_) => onTap(),
        style: const shadcn.ButtonStyle.ghost(
          size: shadcn.ButtonSize.small,
          density: shadcn.ButtonDensity.iconComfortable,
        ),
        selectedStyle: const shadcn.ButtonStyle.secondary(
          size: shadcn.ButtonSize.small,
          density: shadcn.ButtonDensity.iconComfortable,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.indigo500 : AppColors.slate400,
            ),
            const SizedBox(height: 6),
            AnimatedOpacity(
              opacity: isActive ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? AppColors.indigo500 : AppColors.slate400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
