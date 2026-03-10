import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:play_beats/core/theme/app_theme.dart';
import 'package:play_beats/features/browse/screens/browse_screen.dart';
import 'package:play_beats/features/favorites/screens/favorites_screen.dart';
import 'package:play_beats/features/player/widgets/mini_player.dart';
import 'package:play_beats/features/songs/screens/songs_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final _browseKey = GlobalKey<BrowseScreenState>();

  late final List<Widget> _screens = [
    const SongsScreen(),
    BrowseScreen(key: _browseKey),
    const FavoritesScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);

    // Lazy-load browse data on first visit to avoid concurrent
    // on_audio_query method channel calls that crash the plugin.
    if (index == 1) {
      _browseKey.currentState?.loadIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          _BottomNavBar(
            selected: _currentIndex,
            onTap: _onTabTapped,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
//  BOTTOM NAV BAR
// ═════════════════════════════════════════════════════════════════
class _BottomNavBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.selected, required this.onTap});

  static const _labels = ['Home', 'Browse', 'Saved'];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: c.shadowDark,
            offset: const Offset(0, 6),
            blurRadius: 18,
          ),
          BoxShadow(
            color: c.shadowLight,
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: c.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: c.accent.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: _navItem(context, i, c),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, AppColors c) {
    final isActive = selected == index;
    final icon = _iconForIndex(index, isActive, c);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(
          vertical: isActive ? 10 : 12,
        ),
        decoration: isActive
            ? BoxDecoration(
                color: c.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: c.accent.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: c.accent.withValues(alpha: 0.08),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ],
              )
            : BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            if (isActive) ...[
              const SizedBox(height: 4),
              Text(
                _labels[index],
                style: TextStyle(
                  color: c.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _iconForIndex(int index, bool active, AppColors c) {
    switch (index) {
      case 0:
        return SizedBox(
          width: 24,
          height: 24,
          child: CustomPaint(
            painter: _HomePainter(
              active: active,
              activeColor: c.accent,
              inactiveColor: c.iconDim,
            ),
          ),
        );
      case 1:
        return SizedBox(
          width: 26,
          height: 26,
          child: CustomPaint(
            painter: _PlanetPainter(
              active: active,
              activeColor: c.accent,
              inactiveColor: c.iconDim,
            ),
          ),
        );
      case 2:
        return SizedBox(
          width: 22,
          height: 24,
          child: CustomPaint(
            painter: _BookmarkPainter(
              active: active,
              activeColor: c.accent,
              inactiveColor: c.iconDim,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Home Painter ────────────────────────────────────────────────
class _HomePainter extends CustomPainter {
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  _HomePainter(
      {required this.active,
      required this.activeColor,
      required this.inactiveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final color = active ? activeColor : inactiveColor;
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Roof
    final roof = Path()
      ..moveTo(w * 0.1, h * 0.45)
      ..lineTo(w * 0.5, h * 0.08)
      ..lineTo(w * 0.9, h * 0.45);
    canvas.drawPath(roof, strokePaint);

    // Walls
    final walls = Path()
      ..moveTo(w * 0.2, h * 0.42)
      ..lineTo(w * 0.2, h * 0.88)
      ..lineTo(w * 0.8, h * 0.88)
      ..lineTo(w * 0.8, h * 0.42);
    canvas.drawPath(walls, strokePaint);

    // Door – filled when active
    final door = Path()
      ..moveTo(w * 0.4, h * 0.88)
      ..lineTo(w * 0.4, h * 0.62)
      ..lineTo(w * 0.6, h * 0.62)
      ..lineTo(w * 0.6, h * 0.88);
    if (active) {
      canvas.drawPath(
        door,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      );
    }
    canvas.drawPath(door, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _HomePainter old) => old.active != active;
}

// ─── Planet / Saturn Painter ─────────────────────────────────────
class _PlanetPainter extends CustomPainter {
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  _PlanetPainter(
      {required this.active,
      required this.activeColor,
      required this.inactiveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final color = active ? activeColor : inactiveColor;
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;

    // Planet body (filled for active, stroke for inactive)
    final planetPaint = Paint()
      ..color = color
      ..style = active ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(Offset(cx, cy), w * 0.26, planetPaint);

    // Ring (tilted ellipse)
    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final ringRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: w * 0.88,
      height: h * 0.32,
    );

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-0.35);
    canvas.translate(-cx, -cy);
    canvas.drawOval(ringRect, ringPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlanetPainter old) => old.active != active;
}

// ─── Bookmark Painter ────────────────────────────────────────────
class _BookmarkPainter extends CustomPainter {
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  _BookmarkPainter(
      {required this.active,
      required this.activeColor,
      required this.inactiveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final color = active ? activeColor : inactiveColor;
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.15, h * 0.08)
      ..lineTo(w * 0.15, h * 0.92)
      ..lineTo(w * 0.5, h * 0.72)
      ..lineTo(w * 0.85, h * 0.92)
      ..lineTo(w * 0.85, h * 0.08)
      ..close();

    if (active) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill,
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BookmarkPainter old) => old.active != active;
}
