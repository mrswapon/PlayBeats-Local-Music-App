import 'dart:math';
import 'package:flutter/material.dart';

/// Neumorphic decoration helpers.
class Neu {
  Neu._();

  /// Raised card / container.
  static BoxDecoration raised({
    double radius = 20,
    required Color color,
    required Color shadowDark,
    required Color shadowLight,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: shadowDark,
          offset: const Offset(6, 6),
          blurRadius: 16,
        ),
        BoxShadow(
          color: shadowLight,
          offset: const Offset(-4, -4),
          blurRadius: 12,
        ),
      ],
    );
  }

  /// Pressed / inset container.
  static BoxDecoration pressed({
    double radius = 20,
    required Color color,
    required Color shadowDark,
    required Color shadowLight,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: shadowDark,
          offset: const Offset(4, 4),
          blurRadius: 8,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: shadowLight.withValues(alpha: 0.4),
          offset: const Offset(-3, -3),
          blurRadius: 8,
          spreadRadius: -2,
        ),
      ],
    );
  }

  /// Circular neumorphic button / container.
  static BoxDecoration circular({
    double size = 60,
    required Color color,
    required Color bgColor,
    required Color shadowDark,
    required Color shadowLight,
    bool isPressed = false,
  }) {
    if (isPressed) {
      return BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: shadowDark,
            offset: const Offset(3, 3),
            blurRadius: 6,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: shadowLight.withValues(alpha: 0.3),
            offset: const Offset(-2, -2),
            blurRadius: 6,
            spreadRadius: -1,
          ),
        ],
      );
    }
    return BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: shadowDark,
          offset: const Offset(5, 5),
          blurRadius: 14,
        ),
        BoxShadow(
          color: shadowLight,
          offset: const Offset(-4, -4),
          blurRadius: 10,
        ),
      ],
    );
  }
}

/// Draws an arc-progress ring with a glowing dot at the tip.
class ArcProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Color bgColor;

  ArcProgressPainter({
    required this.progress,
    this.strokeWidth = 4,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    // Background track
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow dot at tip
    final dotAngle = -pi / 2 + sweepAngle;
    final dotCenter = Offset(
      center.dx + radius * cos(dotAngle),
      center.dy + radius * sin(dotAngle),
    );

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(dotCenter, 5, glowPaint);

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(dotCenter, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant ArcProgressPainter old) =>
      old.progress != progress;
}
