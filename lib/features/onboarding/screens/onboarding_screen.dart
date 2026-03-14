import 'dart:math';
import 'package:flutter/material.dart';
import 'package:play_beats/data/services/hive_service.dart';
import 'package:play_beats/features/shell/screens/app_shell.dart';

// ─── Onboarding-specific palette ─────────────────────────────
class _OC {
  // Light theme
  static const lightBg1 = Color(0xFFF5F5FC);
  static const lightBg2 = Color(0xFFEEEEF8);
  static const lightBg3 = Color(0xFFF0F0FA);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0x10000000);
  static const lightTextBright = Color(0xFF1A1A2E);
  
  // Dark theme
  static const darkBg1 = Color(0xFF1A1A2E);
  static const darkBg2 = Color(0xFF16162A);
  static const darkBg3 = Color(0xFF18182C);
  static const darkCard = Color(0xFF2A2A3C);
  static const darkBorder = Color(0x10FFFFFF);
  static const darkTextBright = Color(0xFFE0E0E0);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _floatController;
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  Future<void> _loadTheme() async {
    final box = await HiveService.settingsBox;
    final idx = box.get('theme_mode', defaultValue: 0);
    if (mounted) {
      setState(() {
        _isDark = idx == 1;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _onGetStarted() async {
    await HiveService.setOnboardingComplete();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isDark
                ? const [_OC.darkBg1, _OC.darkBg2, _OC.darkBg3, _OC.darkBg1]
                : const [_OC.lightBg1, _OC.lightBg2, _OC.lightBg3, _OC.lightBg1],
            stops: const [0, 0.3, 0.6, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildIllustrationCard(size),
                const SizedBox(height: 40),
                _buildTitle(),
                const Spacer(),
                _buildButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustrationCard(Size screenSize) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final offset = sin(_floatController.value * pi) * 4;
        return Transform.translate(
          offset: Offset(0, offset),
          child: child,
        );
      },
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _fadeController,
          curve: const Interval(0, 0.6, curve: Curves.easeOut),
        ),
        child: Container(
          width: double.infinity,
          height: screenSize.height * 0.42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (_isDark ? _OC.darkCard : _OC.lightCard).withValues(alpha: 0.5),
                (_isDark ? _OC.darkBg2 : _OC.lightBg2).withValues(alpha: 0.7),
              ],
            ),
            border: Border.all(color: _isDark ? _OC.darkBorder : _OC.lightBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: (_isDark ? Colors.black : Colors.white).withValues(alpha: 0.08),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Ambient glow
                Positioned(
                  top: -30,
                  right: -20,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6A6ABB).withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Vinyl records
                Positioned(
                  left: 10,
                  top: 20,
                  child: _VinylPainterWidget(size: 110),
                ),
                Positioned(
                  left: 75,
                  top: 55,
                  child: _VinylPainterWidget(size: 100),
                ),

                // CD
                Positioned(
                  right: 10,
                  top: 10,
                  child: _CDPainterWidget(size: 120),
                ),

                // Cassette
                Positioned(
                  left: 60,
                  bottom: 20,
                  child: _CassettePainterWidget(width: 200),
                ),

                // Bottom fade
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          (_isDark ? _OC.darkBg1 : _OC.lightBg1).withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "New"
        FadeTransition(
          opacity: CurvedAnimation(
            parent: _fadeController,
            curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _fadeController,
              curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
            )),
            child: Text(
              'New',
              style: TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w900,
                color: _isDark ? _OC.darkTextBright : _OC.lightTextBright,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
          ),
        ),

        // "Age Of" - italic, muted gradient
        FadeTransition(
          opacity: CurvedAnimation(
            parent: _fadeController,
            curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _fadeController,
              curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
            )),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: _isDark
                    ? const [Color(0xFF8A8AAE), Color(0xFFAAAACE)]
                    : const [Color(0xFF2A2A3E), Color(0xFF6A6A7E)],
              ).createShader(bounds),
              child: Text(
                'Age Of',
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: _isDark ? const Color(0xFFC0C0E0) : Colors.white,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),

        // "Music"
        FadeTransition(
          opacity: CurvedAnimation(
            parent: _fadeController,
            curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _fadeController,
              curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
            )),
            child: Text(
              'Music',
              style: TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w900,
                color: _isDark ? _OC.darkTextBright : _OC.lightTextBright,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.4),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _fadeController,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
        )),
        child: SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: _onGetStarted,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isDark ? const Color(0xFF2A2A4E) : const Color(0xFF1A1A2E),
              foregroundColor: _isDark ? const Color(0xFFE0E0E0) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            child: const Text('Get Started'),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
//  CUSTOM PAINTERS
// ═════════════════════════════════════════════════════════════════

class _VinylPainterWidget extends StatelessWidget {
  final double size;
  const _VinylPainterWidget({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _VinylPainter()),
    );
  }
}

class _VinylPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;

    final discPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFF3A3A4A),
          Color(0xFF2A2A38),
          Color(0xFF1A1A28),
          Color(0xFF28283A),
        ],
        stops: const [0, 0.35, 0.7, 1],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, discPaint);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 0.5,
    );

    for (final gr in [0.3, 0.38, 0.46, 0.54, 0.62, 0.7, 0.82]) {
      canvas.drawCircle(
        c,
        r * gr,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withValues(alpha: 0.04)
          ..strokeWidth = 0.5,
      );
    }

    canvas.drawCircle(c, r * 0.22, Paint()..color = const Color(0xFF1A1A26));
    canvas.drawCircle(
      c,
      r * 0.22,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 0.5,
    );

    canvas.drawCircle(c, r * 0.05, Paint()..color = const Color(0xFF333345));

    final shinePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Colors.white.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, shinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CDPainterWidget extends StatelessWidget {
  final double size;
  const _CDPainterWidget({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CDPainter()),
    );
  }
}

class _CDPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;

    final basePaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFF555568),
          Color(0xFF44445A),
          Color(0xFF3A3A50),
          Color(0xFF2E2E42),
        ],
        stops: const [0, 0.3, 0.6, 1],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, basePaint);

    for (final gr in [0.28, 0.36, 0.44, 0.52, 0.6, 0.72, 0.82, 0.92]) {
      canvas.drawCircle(
        c,
        r * gr,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withValues(alpha: 0.03)
          ..strokeWidth = 0.5,
      );
    }

    final rainbowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x1A788CFF),
          Color(0x18C878FF),
          Color(0x14FFB478),
          Color(0x1878FFC8),
          Color(0x1C78A0FF),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, rainbowPaint);

    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-0.5, -1),
        end: const Alignment(0.5, 1),
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.transparent,
          Colors.white.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, shinePaint);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 0.8,
    );

    canvas.drawCircle(
      c,
      r * 0.38,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 0.5,
    );

    for (var angle = 0; angle < 360; angle += 45) {
      final rad = angle * pi / 180;
      canvas.drawLine(
        Offset(c.dx + r * 0.2 * cos(rad), c.dy + r * 0.2 * sin(rad)),
        Offset(c.dx + r * 0.36 * cos(rad), c.dy + r * 0.36 * sin(rad)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..strokeWidth = 0.5,
      );
    }

    canvas.drawCircle(c, r * 0.14, Paint()..color = const Color(0xFF1A1A28));
    canvas.drawCircle(
      c,
      r * 0.14,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.1)
        ..strokeWidth = 0.8,
    );

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.8;
    final path = Path();
    for (var x = -r; x <= r; x += 2) {
      final y = sin(x * 0.08) * 8;
      if (x == -r) {
        path.moveTo(c.dx + x, c.dy + y);
      } else {
        path.lineTo(c.dx + x, c.dy + y);
      }
    }
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CassettePainterWidget extends StatelessWidget {
  final double width;
  const _CassettePainterWidget({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.62,
      child: CustomPaint(painter: _CassettePainter()),
    );
  }
}

class _CassettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, w - 8, h - 8),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF38384E), Color(0xFF2A2A3E)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 0.8,
    );

    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, h * 0.08, w * 0.8, h * 0.28),
      const Radius.circular(4),
    );
    canvas.drawRRect(
        labelRect, Paint()..color = Colors.white.withValues(alpha: 0.03));
    canvas.drawRRect(
      labelRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 0.5,
    );

    final linePaint = Paint()..strokeWidth = 0.7;
    for (var i = 0; i < 3; i++) {
      linePaint.color = Colors.white.withValues(alpha: 0.12 - i * 0.03);
      canvas.drawLine(
        Offset(w * 0.14, h * 0.15 + i * h * 0.05),
        Offset(w * 0.14 + (50 - i * 12), h * 0.15 + i * h * 0.05),
        linePaint,
      );
    }

    final bRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.7, h * 0.1, w * 0.17, h * 0.22),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      bRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 0.5,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'B',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.2),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(w * 0.765, h * 0.14));

    final winRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.42, w * 0.72, h * 0.38),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      winRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1E30), Color(0xFF161626)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawRRect(
      winRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 0.5,
    );

    _drawReel(canvas, Offset(w * 0.34, h * 0.6), w * 0.1);
    _drawReel(canvas, Offset(w * 0.66, h * 0.6), w * 0.1);

    canvas.drawLine(
      Offset(w * 0.42, h * 0.6),
      Offset(w * 0.58, h * 0.6),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.04)
        ..strokeWidth = 2,
    );

    final typePainter = TextPainter(
      text: TextSpan(
        text: 'TYPE I \u00b7 IEC I \u00b7 NORMAL',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.12),
          fontSize: 5,
          fontFamily: 'monospace',
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    typePainter.paint(canvas, Offset(w * 0.3, h * 0.76));

    final durPainter = TextPainter(
      text: TextSpan(
        text: '90',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.15),
          fontSize: 9,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    durPainter.paint(canvas, Offset(w * 0.46, h * 0.86));

    canvas.drawCircle(
      Offset(w * 0.14, h * 0.9),
      3,
      Paint()..color = const Color(0xFF222234),
    );
    canvas.drawCircle(
      Offset(w * 0.86, h * 0.9),
      3,
      Paint()..color = const Color(0xFF222234),
    );
  }

  void _drawReel(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 0.5,
    );
    canvas.drawCircle(
      center,
      radius * 0.8,
      Paint()..color = const Color(0xFF1A1A2A),
    );
    canvas.drawCircle(
      center,
      radius * 0.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 0.5,
    );
    canvas.drawCircle(
      center,
      radius * 0.4,
      Paint()..color = const Color(0xFF222234),
    );
    canvas.drawCircle(
      center,
      radius * 0.4,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.1)
        ..strokeWidth = 0.8,
    );
    canvas.drawCircle(
        center, radius * 0.15, Paint()..color = const Color(0xFF2A2A3E));

    for (var a = 0; a < 360; a += 120) {
      final rad = a * pi / 180;
      canvas.drawLine(
        Offset(center.dx + radius * 0.2 * cos(rad),
            center.dy + radius * 0.2 * sin(rad)),
        Offset(center.dx + radius * 0.75 * cos(rad),
            center.dy + radius * 0.75 * sin(rad)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..strokeWidth = 0.6,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
