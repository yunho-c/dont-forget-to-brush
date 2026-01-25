import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (index) {
        final isActive = index < step;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == total - 1 ? 0 : 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.indigo500 : AppColors.night700,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }),
    );
  }
}
