import 'package:flutter/material.dart';

class InfinityLoader extends StatefulWidget {
  final double size;
  final Color color;
  final double strokeWidth;
  final Duration duration;

  const InfinityLoader({
    super.key,
    this.size = 36,
    this.color = const Color(0xFF2E7D32),
    this.strokeWidth = 3,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<InfinityLoader> createState() => _InfinityLoaderState();
}

class _InfinityLoaderState extends State<InfinityLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _InfinityPainter(
              progress: _controller.value,
              color: widget.color,
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class _InfinityPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _InfinityPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(0.1 * w, 0.5 * h);
    path.cubicTo(0.1 * w, 0.1 * h, 0.45 * w, 0.1 * h, 0.5 * w, 0.5 * h);
    path.cubicTo(0.55 * w, 0.9 * h, 0.9 * w, 0.9 * h, 0.9 * w, 0.5 * h);
    path.cubicTo(0.9 * w, 0.1 * h, 0.55 * w, 0.1 * h, 0.5 * w, 0.5 * h);
    path.cubicTo(0.45 * w, 0.9 * h, 0.1 * w, 0.9 * h, 0.1 * w, 0.5 * h);

    final trackPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, trackPaint);

    final metric = path.computeMetrics().first;
    final length = metric.length;
    final dashLength = length * 0.22;
    final start = (progress * length) % length;
    final end = start + dashLength;

    final dashPath = Path();
    if (end <= length) {
      dashPath.addPath(metric.extractPath(start, end), Offset.zero);
    } else {
      dashPath.addPath(metric.extractPath(start, length), Offset.zero);
      dashPath.addPath(metric.extractPath(0, end - length), Offset.zero);
    }

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(dashPath, activePaint);
  }

  @override
  bool shouldRepaint(covariant _InfinityPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
