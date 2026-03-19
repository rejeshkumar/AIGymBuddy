import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Apple Fitness-style activity ring. Single ring with progress.
class ActivityRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color color;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;

  const ActivityRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 80,
    this.strokeWidth = 8,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? color.withOpacity(0.2);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          color: color,
          backgroundColor: bg,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring (start from top, go clockwise)
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    const startAngle = -math.pi / 2; // 12 o'clock
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.backgroundColor != backgroundColor;
}

/// Three concentric rings like Apple Fitness (Move, Exercise, Stand).
class ActivityRings extends StatelessWidget {
  final double moveProgress;   // outer - workouts
  final double exerciseProgress; // middle - streak
  final double standProgress; // inner - today completion
  final double size;

  const ActivityRings({
    super.key,
    required this.moveProgress,
    required this.exerciseProgress,
    required this.standProgress,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    const moveColor = Color(0xFFFA114F);    // Apple red
    const exerciseColor = Color(0xFF30D158); // Apple green
    const standColor = Color(0xFF64D2FF);    // Apple blue

    const strokeWidth = 7.0;
    const gap = 4.0; // gap between rings

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ActivityRing(
            progress: moveProgress,
            color: moveColor,
            size: size,
            strokeWidth: strokeWidth,
          ),
          ActivityRing(
            progress: exerciseProgress,
            color: exerciseColor,
            size: size - (strokeWidth + gap) * 2,
            strokeWidth: strokeWidth,
          ),
          ActivityRing(
            progress: standProgress,
            color: standColor,
            size: size - (strokeWidth + gap) * 4,
            strokeWidth: strokeWidth,
          ),
        ],
      ),
    );
  }
}
