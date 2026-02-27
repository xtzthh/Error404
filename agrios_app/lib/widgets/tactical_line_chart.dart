import 'package:flutter/material.dart';
import '../theme/colors.dart';

class TacticalLineChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double min;
  final double max;

  const TacticalLineChart({
    super.key,
    required this.data,
    required this.color,
    this.min = 0,
    this.max = 100,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _LineChartPainter(data, color, min, max),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double min;
  final double max;

  _LineChartPainter(this.data, this.color, this.min, this.max);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double stepX = size.width / (data.length - 1);
    final double range = max - min;

    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      final double y = size.height - ((data[i] - min) / range * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw a subtle shadow/glow under the line
    final glowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(path, glowPaint);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

