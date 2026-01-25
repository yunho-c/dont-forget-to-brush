import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.showLine = false});

  final Widget child;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.night950,
                AppColors.night900,
                AppColors.night950,
              ],
            ),
          ),
        ),
        if (showLine)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: CustomPaint(painter: _BackgroundLinePainter()),
          ),
        child,
      ],
    );
  }
}

class _BackgroundLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.indigo500.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();
    path.moveTo(0, size.height * 0.55);
    path.cubicTo(
      size.width * 0.2,
      size.height * 0.4,
      size.width * 0.4,
      size.height * 0.7,
      size.width * 0.6,
      size.height * 0.5,
    );
    path.cubicTo(
      size.width * 0.75,
      size.height * 0.35,
      size.width * 0.9,
      size.height * 0.6,
      size.width,
      size.height * 0.45,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
