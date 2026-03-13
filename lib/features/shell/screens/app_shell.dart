import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:play_beats/core/theme/app_theme.dart';
import 'package:play_beats/features/browse/screens/browse_screen.dart';
import 'package:play_beats/features/player/widgets/mini_player.dart';
import 'package:play_beats/features/playlists/screens/playlists_screen.dart';
import 'package:play_beats/features/songs/screens/songs_screen.dart';
import 'package:play_beats/features/videos/screens/videos_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final _browseKey = GlobalKey<BrowseScreenState>();

  late final List<Widget> _screens = [
    const VideosScreen(),
    const SongsScreen(),
    BrowseScreen(key: _browseKey),
    const PlaylistsScreen(),
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
class _BottomNavBar extends StatefulWidget {
  final int selected;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.selected, required this.onTap});

  @override
  State<_BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<_BottomNavBar>
    with TickerProviderStateMixin {
  static const _labels = ['Videos', 'Songs', 'Browse', 'Playlists'];
  late final List<AnimationController> _tabControllers;

  @override
  void initState() {
    super.initState();
    _tabControllers = List.generate(
      4,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 380),
        value: i == widget.selected ? 1.0 : 0.0,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _BottomNavBar old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) {
      for (int i = 0; i < 4; i++) {
        if (i == widget.selected) {
          _tabControllers[i].forward();
        } else {
          _tabControllers[i].reverse();
        }
      }
    }
  }

  @override
  void dispose() {
    for (final c in _tabControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: c.accent.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: c.shadowDark.withValues(alpha: 0.35),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
          BoxShadow(
            color: c.shadowLight.withValues(alpha: 0.5),
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 74,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  c.surface.withValues(alpha: 0.95),
                  c.surface.withValues(alpha: 0.82),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: c.accent.withValues(alpha: 0.05),
                width: 0.8,
              ),
            ),
            child: Row(
              children: List.generate(4, (i) {
                return Expanded(child: _buildNavItem(i, c));
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, AppColors c) {
    final anim = CurvedAnimation(
      parent: _tabControllers[index],
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return GestureDetector(
      onTap: () => widget.onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, _) {
          final t = anim.value;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: t > 0.01
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        c.accent.withValues(alpha: 0.06 * t),
                        c.accent.withValues(alpha: 0.12 * t),
                      ],
                    )
                  : null,
              border: t > 0.01
                  ? Border.all(
                      color: c.accent.withValues(alpha: 0.08 * t),
                      width: 0.6,
                    )
                  : null,
              boxShadow: t > 0.5
                  ? [
                      BoxShadow(
                        color: c.accent.withValues(alpha: 0.08 * t),
                        blurRadius: 14,
                        spreadRadius: -3,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with smooth scale
                Transform.scale(
                  scale: 1.0 + 0.1 * t,
                  child: _iconForIndex(index, t > 0.5, c),
                ),

                // Label slides in/out
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: t,
                    child: Opacity(
                      opacity: t,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child: Text(
                          _labels[index],
                          style: TextStyle(
                            color: c.accent,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _iconForIndex(int index, bool active, AppColors c) {
    switch (index) {
      case 0:
        return SizedBox(
          width: 22,
          height: 22,
          child: CustomPaint(
            painter: _VideoNavPainter(
              active: active,
              activeColor: c.accent,
              inactiveColor: c.iconDim,
            ),
          ),
        );
      case 1:
        return SizedBox(
          width: 22,
          height: 22,
          child: CustomPaint(
            painter: _VinylNavPainter(
              active: active,
              activeColor: c.accent,
              inactiveColor: c.iconDim,
            ),
          ),
        );
      case 2:
        return SizedBox(
          width: 22,
          height: 22,
          child: CustomPaint(
            painter: _PlanetPainter(
              active: active,
              activeColor: c.accent,
              inactiveColor: c.iconDim,
            ),
          ),
        );
      case 3:
        return SizedBox(
          width: 22,
          height: 22,
          child: CustomPaint(
            painter: _PlaylistNavPainter(
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

// ─── Vinyl Disc (Home) ──────────────────────────────────────────
class _VinylNavPainter extends CustomPainter {
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  _VinylNavPainter(
      {required this.active,
      required this.activeColor,
      required this.inactiveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final color = active ? activeColor : inactiveColor;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;

    // Filled disc background when active
    if (active) {
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = color.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill,
      );
    }

    // Outer ring
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Grooves
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(
        Offset(cx, cy),
        r * (0.3 + i * 0.15),
        Paint()
          ..color = color.withValues(alpha: active ? 0.3 : 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Center hole
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.14,
      Paint()
        ..color = color
        ..style = active ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant _VinylNavPainter old) => old.active != active;
}

// ─── Planet / Saturn (Browse) ───────────────────────────────────
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

    // Planet body
    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.26,
      Paint()
        ..color = color
        ..style = active ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

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

// ─── Playlist Icon (Playlists) ──────────────────────────────────
class _PlaylistNavPainter extends CustomPainter {
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  _PlaylistNavPainter(
      {required this.active,
      required this.activeColor,
      required this.inactiveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final color = active ? activeColor : inactiveColor;
    final w = size.width;
    final h = size.height;

    // Background fill when active
    if (active) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.1, h * 0.15, w * 0.8, h * 0.7),
          const Radius.circular(4),
        ),
        Paint()..color = color.withValues(alpha: 0.15),
      );
    }

    // List lines
    for (var i = 0; i < 3; i++) {
      final y = h * 0.3 + i * h * 0.18;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.2, y, w * 0.65, h * 0.12),
          const Radius.circular(2),
        ),
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }

    // Play triangle on left
    final playPath = Path()
      ..moveTo(w * 0.18, h * 0.35)
      ..lineTo(w * 0.18, h * 0.65)
      ..lineTo(w * 0.38, h * 0.5)
      ..close();
    canvas.drawPath(
      playPath,
      Paint()
        ..color = color
        ..style = active ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _PlaylistNavPainter old) => old.active != active;
}

// ─── Video Icon (Videos) ────────────────────────────────────────
class _VideoNavPainter extends CustomPainter {
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  _VideoNavPainter(
      {required this.active,
      required this.activeColor,
      required this.inactiveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final color = active ? activeColor : inactiveColor;
    final w = size.width;
    final h = size.height;

    // Rectangle frame
    final frameRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.05, h * 0.2, w * 0.9, h * 0.6),
      const Radius.circular(4),
    );

    if (active) {
      canvas.drawRRect(
        frameRect,
        Paint()..color = color.withValues(alpha: 0.15),
      );
    }

    canvas.drawRRect(
      frameRect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Play triangle in center
    final playPath = Path()
      ..moveTo(w * 0.42, h * 0.35)
      ..lineTo(w * 0.42, h * 0.65)
      ..lineTo(w * 0.68, h * 0.5)
      ..close();
    canvas.drawPath(
      playPath,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _VideoNavPainter old) => old.active != active;
}
