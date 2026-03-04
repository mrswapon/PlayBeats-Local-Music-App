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
          _DarkBottomNavBar(
            selected: _currentIndex,
            onTap: _onTabTapped,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
//  DARK BOTTOM NAV BAR
// ═════════════════════════════════════════════════════════════════
class _DarkBottomNavBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;

  const _DarkBottomNavBar({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: c.shadowDark,
              offset: const Offset(0, 8),
              blurRadius: 20),
          BoxShadow(
              color: c.shadowLight,
              offset: const Offset(0, -2),
              blurRadius: 10),
        ],
        border: Border.all(
            color: c.accent.withValues(alpha: 0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(context, 0, _homeIcon),
          _navItem(context, 1, _planetIcon),
          _navItem(context, 2, _bookmarkIcon),
        ],
      ),
    );
  }

  Widget _navItem(
      BuildContext context, int index, Widget Function(bool active, AppColors c) iconBuilder) {
    final c = context.colors;
    final isActive = selected == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        width: 56,
        height: 48,
        decoration: isActive
            ? BoxDecoration(
                color: c.surfaceLight,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: c.shadowDark,
                      offset: const Offset(3, 3),
                      blurRadius: 8),
                  BoxShadow(
                      color: c.shadowLight.withValues(alpha: 0.4),
                      offset: const Offset(-2, -2),
                      blurRadius: 6),
                ],
              )
            : BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
        child: Center(child: iconBuilder(isActive, c)),
      ),
    );
  }

  // ── Home Icon ──
  Widget _homeIcon(bool active, AppColors c) => SizedBox(
        width: 24,
        height: 24,
        child: CustomPaint(
            painter: _HomePainter(
                active: active,
                activeColor: c.accent,
                inactiveColor: c.iconDim)),
      );

  // ── Planet / Saturn Icon ──
  Widget _planetIcon(bool active, AppColors c) => SizedBox(
        width: 26,
        height: 26,
        child: CustomPaint(
            painter: _PlanetPainter(
                active: active,
                activeColor: c.accent,
                inactiveColor: c.iconDim)),
      );

  // ── Bookmark Icon ──
  Widget _bookmarkIcon(bool active, AppColors c) => SizedBox(
        width: 22,
        height: 24,
        child: CustomPaint(
            painter: _BookmarkPainter(
                active: active,
                activeColor: c.accent,
                inactiveColor: c.iconDim)),
      );
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
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Roof
    final roof = Path()
      ..moveTo(w * 0.1, h * 0.45)
      ..lineTo(w * 0.5, h * 0.08)
      ..lineTo(w * 0.9, h * 0.45);
    canvas.drawPath(roof, paint);

    // Walls
    final walls = Path()
      ..moveTo(w * 0.2, h * 0.42)
      ..lineTo(w * 0.2, h * 0.88)
      ..lineTo(w * 0.8, h * 0.88)
      ..lineTo(w * 0.8, h * 0.42);
    canvas.drawPath(walls, paint);

    // Door
    final door = Path()
      ..moveTo(w * 0.4, h * 0.88)
      ..lineTo(w * 0.4, h * 0.62)
      ..lineTo(w * 0.6, h * 0.62)
      ..lineTo(w * 0.6, h * 0.88);
    canvas.drawPath(door, paint);
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

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(w * 0.15, h * 0.08)
      ..lineTo(w * 0.15, h * 0.92)
      ..lineTo(w * 0.5, h * 0.72)
      ..lineTo(w * 0.85, h * 0.92)
      ..lineTo(w * 0.85, h * 0.08)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BookmarkPainter old) => old.active != active;
}
