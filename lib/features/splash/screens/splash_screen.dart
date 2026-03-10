import 'dart:math';
import 'package:flutter/material.dart';
import 'package:play_beats/data/services/hive_service.dart';
import 'package:play_beats/features/onboarding/screens/onboarding_screen.dart';
import 'package:play_beats/features/shell/screens/app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _textController;
  late final AnimationController _exitController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    // Disc scale + spin
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Text fade + slide
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Glow pulse
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Exit fade-out
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigate();
      }
    });

    // Start the animation sequence
    _scaleController.forward();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _textController.forward();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _glowController.forward();
    });

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) _exitController.forward();
    });
  }

  void _navigate() {
    if (!mounted) return;
    final destination = HiveService.isOnboardingComplete
        ? const AppShell()
        : const OnboardingScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: const Duration(seconds: 2),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _textController.dispose();
    _glowController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final discSize = size.width * 0.42;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F1A),
              Color(0xFF151528),
              Color(0xFF1A1A30),
              Color(0xFF0F0F1A),
            ],
            stops: [0, 0.3, 0.6, 1],
          ),
        ),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
            CurvedAnimation(
              parent: _exitController,
              curve: Curves.easeIn,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Vinyl disc with glow ──
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _scaleController,
                  curve: Curves.easeOutBack,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow ring
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (_, __) {
                        final glow = _glowController.value;
                        return Container(
                          width: discSize + 40,
                          height: discSize + 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4A4A8A)
                                    .withValues(alpha: 0.15 + glow * 0.15),
                                blurRadius: 40 + glow * 20,
                                spreadRadius: 5 + glow * 10,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Spinning vinyl
                    RotationTransition(
                      turns: Tween<double>(begin: 0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _scaleController,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: SizedBox(
                        width: discSize,
                        height: discSize,
                        child: CustomPaint(
                          painter: _SplashVinylPainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ── App name ──
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _textController,
                  curve: Curves.easeOut,
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _textController,
                    curve: Curves.easeOutCubic,
                  )),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PlayBeats',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Color(0xF0F0F0FA),
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Feel the rhythm',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0x88B4B4D2),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
//  SPLASH VINYL PAINTER
// ═════════════════════════════════════════════════════════════════
class _SplashVinylPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Outer disc
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0xFF2A2A3C),
            Color(0xFF1A1A28),
            Color(0xFF111118),
            Color(0xFF1A1A28),
            Color(0xFF0E0E16),
          ],
          stops: const [0, 0.25, 0.5, 0.75, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Grooves
    for (var i = 0; i < 30; i++) {
      final gr = r * 0.28 + (r * 0.68) * (i / 30);
      canvas.drawCircle(
        c,
        gr,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withValues(alpha: i.isEven ? 0.04 : 0.015)
          ..strokeWidth = 0.4,
      );
    }

    // Shine arc
    canvas.drawPath(
      Path()
        ..addArc(
          Rect.fromCircle(center: c, radius: r * 0.7),
          -pi * 0.8,
          pi * 0.35,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.07)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    // Second subtle shine
    canvas.drawPath(
      Path()
        ..addArc(
          Rect.fromCircle(center: c, radius: r * 0.45),
          -pi * 0.5,
          pi * 0.2,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.04)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    // Center label
    canvas.drawCircle(c, r * 0.2, Paint()..color = const Color(0xFF3A3A50));
    canvas.drawCircle(
      c,
      r * 0.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 0.5,
    );
    canvas.drawCircle(
      c,
      r * 0.14,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.05)
        ..strokeWidth = 0.4,
    );

    // Center spindle
    canvas.drawCircle(c, r * 0.05, Paint()..color = const Color(0xFFE0E0EC));
    canvas.drawCircle(c, r * 0.02, Paint()..color = const Color(0xFF1C1C28));

    // Rim
    canvas.drawCircle(
      c,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
