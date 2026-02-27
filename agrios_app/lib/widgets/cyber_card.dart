import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../providers/theme_provider.dart';

class CyberCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry padding;
  final bool showCorner;

  const CyberCard({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.padding = const EdgeInsets.all(15),
    this.showCorner = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width ?? double.infinity,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.getCard(isDark),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.getBorder(isDark),
              width: 1,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              child,
              if (showCorner)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CustomPaint(
                    size: const Size(15, 15),
                    painter: CornerBracketPainter(isDark: isDark),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CornerBracketPainter extends CustomPainter {
  final bool isDark;
  CornerBracketPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? AppColors.neonGreen : AppColors.lightText
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width, size.height - 8);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - 8, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
