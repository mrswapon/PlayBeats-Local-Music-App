import 'dart:math';
import 'package:flutter/material.dart';

class ExploreAlbumArt extends StatelessWidget {
  final int variant;
  final double size;

  const ExploreAlbumArt({super.key, required this.variant, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: CustomPaint(
          size: Size(size, size),
          painter: _AlbumPainter(variant: variant, isDark: isDark),
        ),
      ),
    );
  }
}

class _AlbumPainter extends CustomPainter {
  final int variant;
  final bool isDark;
  _AlbumPainter({required this.variant, required this.isDark});

  Color get _overlay => isDark ? Colors.white : Colors.black;

  Color _base(int darkHex, int lightHex) =>
      isDark ? Color(darkHex) : Color(lightHex);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    switch (variant % 7) {
      case 0:
        _paintBoldType(canvas, size, c, r);
      case 1:
        _paintWaves(canvas, size, c, r);
      case 2:
        _paintMinimalCircle(canvas, size, c, r);
      case 3:
        _paintArchive(canvas, size, c, r);
      case 4:
        _paintNoise(canvas, size, c, r);
      case 5:
        _paintSplit(canvas, size, c, r);
      case 6:
        _paintGeometric(canvas, size, c, r);
    }

    canvas.drawCircle(
      c,
      r - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _overlay.withValues(alpha: 0.06)
        ..strokeWidth = 0.5,
    );
  }

  void _paintBoldType(Canvas canvas, Size size, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = _base(0xFF222238, 0xFFD8D8E8));
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(r * 0.2, r * 0.7 + i * r * 0.12),
        Offset(r * 1.6 - i * r * 0.15, r * 0.7 + i * r * 0.12),
        Paint()
          ..color = _overlay.withValues(alpha: 0.08 - i * 0.02)
          ..strokeWidth = 0.7,
      );
    }
    _drawText(canvas, '10', Offset(r * 0.25, r * 0.4), r * 1.0,
        FontWeight.w900, _overlay.withValues(alpha: 0.1));
  }

  void _paintWaves(Canvas canvas, Size size, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = _base(0xFF1E1E32, 0xFFDCDCEC));
    for (var w = 0; w < 3; w++) {
      final path = Path();
      final yBase = r * (0.75 + w * 0.25);
      for (var x = 0.0; x < size.width; x += 2) {
        final y = yBase + sin(x * 0.1 + w) * r * 0.15;
        x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = _overlay.withValues(alpha: 0.1 - w * 0.02)
          ..strokeWidth = 1.2,
      );
    }
    _drawText(canvas, 'DREAMS', Offset(r * 0.35, r * 0.5), r * 0.24,
        FontWeight.w400, _overlay.withValues(alpha: 0.15),
        fontFamily: 'monospace');
  }

  void _paintMinimalCircle(Canvas canvas, Size size, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = _base(0xFF252540, 0xFFD4D4E4));
    canvas.drawCircle(
        c,
        r * 0.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = _overlay.withValues(alpha: 0.1)
          ..strokeWidth = 1);
    canvas.drawCircle(
        c,
        r * 0.3,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = _overlay.withValues(alpha: 0.07)
          ..strokeWidth = 0.8);
    canvas.drawCircle(
        c, r * 0.1, Paint()..color = _overlay.withValues(alpha: 0.08));
    canvas.drawLine(
      Offset(c.dx, c.dy - r * 0.5),
      Offset(c.dx, c.dy - r * 0.8),
      Paint()
        ..color = _overlay.withValues(alpha: 0.06)
        ..strokeWidth = 0.5,
    );
  }

  void _paintArchive(Canvas canvas, Size size, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = _base(0xFF1C1C30, 0xFFE0E0F0));
    canvas.drawRect(
      Rect.fromLTWH(r * 0.25, r * 0.6, r * 1.5, r * 0.75),
      Paint()..color = _overlay.withValues(alpha: 0.04),
    );
    canvas.drawLine(
      Offset(r * 0.25, r * 0.5),
      Offset(r * 1.75, r * 0.5),
      Paint()
        ..color = const Color(0xFFC8B400).withValues(alpha: 0.15)
        ..strokeWidth = 2,
    );
    canvas.drawRect(
      Rect.fromLTWH(r * 1.25, r * 0.7, r * 0.4, r * 0.4),
      Paint()..color = const Color(0xFFC8C800).withValues(alpha: 0.1),
    );
    _drawText(canvas, 'ARCHIVE', Offset(r * 0.3, r * 0.85), r * 0.26,
        FontWeight.w900, _overlay.withValues(alpha: 0.18),
        fontFamily: 'monospace');
  }

  void _paintNoise(Canvas canvas, Size size, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = _base(0xFF20203A, 0xFFDADAEA));
    final rng = Random(42);
    for (var i = 0; i < 80; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      if ((Offset(dx, dy) - c).distance < r * 0.9) {
        canvas.drawCircle(
          Offset(dx, dy),
          rng.nextDouble() * 1.5,
          Paint()
            ..color = _overlay.withValues(alpha: rng.nextDouble() * 0.06),
        );
      }
    }
    _drawText(canvas, 'C', Offset(r * 0.55, r * 0.55), r * 0.9,
        FontWeight.w700, _overlay.withValues(alpha: 0.06),
        fontFamily: 'serif');
  }

  void _paintSplit(Canvas canvas, Size size, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = _base(0xFF1A1A2E, 0xFFDEDEEE));
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..arcTo(Rect.fromCircle(center: c, radius: r), -pi / 2, pi, false)
      ..close();
    canvas.drawPath(path, Paint()..color = _base(0xFF222240, 0xFFD0D0E0));
    canvas.drawCircle(Offset(c.dx - r * 0.25, c.dy - r * 0.12), r * 0.25,
        Paint()..color = _overlay.withValues(alpha: 0.04));
    canvas.drawCircle(Offset(c.dx + r * 0.25, c.dy + r * 0.12), r * 0.2,
        Paint()..color = _overlay.withValues(alpha: 0.03));
    canvas.drawLine(
      Offset(c.dx - r * 0.5, c.dy + r * 0.5),
      Offset(c.dx + r * 0.5, c.dy + r * 0.5),
      Paint()
        ..color = _overlay.withValues(alpha: 0.06)
        ..strokeWidth = 0.5,
    );
  }

  void _paintGeometric(Canvas canvas, Size size, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = _base(0xFF24243C, 0xFFD6D6E6));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(pi / 4);
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset.zero, width: r * 0.75, height: r * 0.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _overlay.withValues(alpha: 0.08)
        ..strokeWidth = 0.8,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: r * 0.5, height: r * 0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _overlay.withValues(alpha: 0.05)
        ..strokeWidth = 0.6,
    );
    canvas.restore();
    canvas.drawCircle(
        c, r * 0.07, Paint()..color = _overlay.withValues(alpha: 0.1));
  }

  void _drawText(Canvas canvas, String text, Offset offset, double fontSize,
      FontWeight weight, Color color,
      {String? fontFamily}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          fontFamily: fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _AlbumPainter old) =>
      old.variant != variant || old.isDark != isDark;
}
