import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/data/services/audio_player_service.dart';
import 'package:play_beats/features/favorites/bloc/favorites_bloc.dart';
import 'package:play_beats/features/favorites/bloc/favorites_event.dart';
import 'package:play_beats/features/favorites/bloc/favorites_state.dart';
import 'package:play_beats/features/player/bloc/player_bloc.dart';
import 'package:play_beats/features/player/bloc/player_event.dart';
import 'package:play_beats/features/player/bloc/player_state.dart';

// ─── Player palette ──────────────────────────────────────────
class _PC {
  final Color bg;
  final Color surface;
  final Color surfaceLight;
  final Color shadowDark;
  final Color shadowLight;
  final Color textPrimary;
  final Color textSecondary;

  const _PC({
    required this.bg,
    required this.surface,
    required this.surfaceLight,
    required this.shadowDark,
    required this.shadowLight,
    required this.textPrimary,
    required this.textSecondary,
  });

  static const dark = _PC(
    bg: Color(0xFF121218),
    surface: Color(0xFF1C1C28),
    surfaceLight: Color(0xFF252535),
    shadowDark: Color(0xFF0A0A10),
    shadowLight: Color(0xFF2A2A3E),
    textPrimary: Color(0xFFF0F0F8),
    textSecondary: Color(0xFF7A7A92),
  );

  static const light = _PC(
    bg: Color(0xFFEDEDF5),
    surface: Color(0xFFF5F5FD),
    surfaceLight: Color(0xFFFFFFFF),
    shadowDark: Color(0xFFC8C8D8),
    shadowLight: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF8A8A9E),
  );

  static _PC of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

// ═════════════════════════════════════════════════════════════════
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _eqController;
  late final AnimationController _armController;

  _PC get _p => _PC.of(context);

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _eqController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _armController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: (context.read<PlayerBloc>().state is PlayerPlaying) ? 1.0 : 0.0,
    );

    // Sync initial spin state with player
    final state = context.read<PlayerBloc>().state;
    if (state is PlayerPlaying) _spinController.repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _eqController.dispose();
    _armController.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final ttSize = sw * 0.88;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_p.bg, Color.lerp(_p.bg, _p.surface, 0.5)!, _p.bg],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocConsumer<PlayerBloc, PlayerState>(
        listener: (context, state) {
          if (state is PlayerPlaying) {
            _spinController.repeat();
            _armController.animateTo(1.0, curve: Curves.easeOutCubic);
          } else {
            _spinController.stop();
            _armController.animateTo(0.0, curve: Curves.easeInCubic);
          }
        },
        builder: (context, state) {
          final song = state.currentSong;
          if (song == null) {
            return Center(
              child: Text(
                'No song selected',
                style: TextStyle(color: _p.textSecondary),
              ),
            );
          }

          final isPlaying = state is PlayerPlaying;
          final isBuffering = state is PlayerBuffering;
          final audioService = context.read<AudioPlayerService>();

          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildTopBar(state),
                const SizedBox(height: 20),
                _buildTurntable(ttSize, isPlaying),
                const SizedBox(height: 20),

                // ── Song info ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    song.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _p.textPrimary,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  song.artist,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _p.textSecondary,
                  ),
                ),

                const Spacer(),

                // ── Equalizer ──
                _buildEqualizer(isPlaying),
                const SizedBox(height: 16),

                // ── Progress bar ──
                _buildProgressBar(audioService),
                const SizedBox(height: 20),

                // ── Controls ──
                _buildControls(isPlaying, isBuffering),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────
  Widget _buildTopBar(PlayerState state) {
    final song = state.currentSong;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: _neuCircleIcon(Icons.arrow_back_ios_new_rounded, 42, 18),
          ),
          const SizedBox(width: 12),
          BlocBuilder<FavoritesBloc, FavoritesState>(
            builder: (context, favState) {
              final isFav = favState is FavoritesLoaded &&
                  song != null &&
                  favState.isFavorite(song.id);
              return GestureDetector(
                onTap: () {
                  if (song == null) return;
                  if (isFav) {
                    context
                        .read<FavoritesBloc>()
                        .add(RemoveFromFavorites(song.id));
                  } else {
                    context
                        .read<FavoritesBloc>()
                        .add(AddToFavorites(song));
                  }
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: _neuCircle(),
                  child: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color:
                        isFav ? const Color(0xFFE06080) : _p.textSecondary,
                    size: 18,
                  ),
                ),
              );
            },
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showPlaylistSheet(state),
            child: _neuCircleIcon(Icons.queue_music_rounded, 42, 20),
          ),
        ],
      ),
    );
  }

  Widget _neuCircleIcon(IconData icon, double size, double iconSize) {
    return Container(
      width: size,
      height: size,
      decoration: _neuCircle(),
      child: Icon(icon, color: _p.textSecondary, size: iconSize),
    );
  }

  // ── Turntable ───────────────────────────────────────────────
  Widget _buildTurntable(double size, bool isPlaying) {
    return Center(
      child: Container(
        width: size,
        height: size * 0.88,
        decoration: _neuRaised(radius: 18, color: _p.surface),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _BasePainter())),

              // Vinyl
              Positioned(
                left: size * 0.06,
                top: size * 0.1,
                child: AnimatedBuilder(
                  animation: _spinController,
                  builder: (_, child) => Transform.rotate(
                    angle: _spinController.value * 2 * pi,
                    child: child,
                  ),
                  child: SizedBox(
                    width: size * 0.65,
                    height: size * 0.65,
                    child: CustomPaint(painter: _VinylPainter()),
                  ),
                ),
              ),

              // Tonearm
              Positioned(
                right: size * 0.04,
                top: size * 0.02,
                child: AnimatedBuilder(
                  animation: _armController,
                  builder: (_, __) => SizedBox(
                    width: size * 0.32,
                    height: size * 0.8,
                    child: CustomPaint(
                      painter: _ArmPainter(
                          armPosition: _armController.value),
                    ),
                  ),
                ),
              ),

              // Corner screws
              Positioned(left: size * 0.04, top: size * 0.035, child: _screw()),
              Positioned(
                right: size * 0.04,
                top: size * 0.035,
                child: _screw(),
              ),

              // Knobs
              Positioned(
                left: size * 0.055,
                bottom: size * 0.05,
                child: _knob(),
              ),
              Positioned(
                right: size * 0.055,
                bottom: size * 0.05,
                child: _knob(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Turntable hardware – always dark regardless of theme
  Widget _screw() => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF252535),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 2,
          offset: const Offset(0.5, 0.5),
        ),
      ],
    ),
    child: CustomPaint(painter: _ScrewPainter()),
  );

  Widget _knob() => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF252535),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 4,
          offset: const Offset(1, 1),
        ),
      ],
    ),
    child: Center(
      child: Container(
        width: 3,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );

  // ── Equalizer ───────────────────────────────────────────────
  Widget _buildEqualizer(bool isPlaying) {
    const barCount = 15;
    const mid = (barCount - 1) / 2.0;
    return AnimatedBuilder(
      animation: _eqController,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(barCount, (i) {
          final dist = (i - mid).abs() / mid;
          final base = 10.0 + (1 - dist) * 28;
          final h = isPlaying
              ? base + sin(_eqController.value * pi + i * 0.6) * 12
              : base * 0.35;
          final brightness = 0.4 + (1 - dist) * 0.5;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 4.5,
            height: h.clamp(4.0, 44.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _p.textPrimary.withValues(alpha: brightness * 0.7),
                  _p.textSecondary.withValues(alpha: brightness * 0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }

  // ── Progress bar ─────────────────────────────────────────────
  Widget _buildProgressBar(AudioPlayerService audioService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: StreamBuilder<Duration>(
        stream: audioService.player.positionStream,
        builder: (context, snapshot) {
          final pos = snapshot.data ?? Duration.zero;
          final dur = audioService.player.duration ?? Duration.zero;
          final posMs = pos.inMilliseconds.toDouble();
          final durMs = dur.inMilliseconds.toDouble();

          return Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: _p.textPrimary,
                  inactiveTrackColor: _p.textSecondary.withValues(alpha: 0.15),
                  thumbColor: _p.textPrimary,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayColor: _p.textPrimary.withValues(alpha: 0.1),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: durMs > 0 ? posMs.clamp(0, durMs) : 0,
                  max: durMs > 0 ? durMs : 1,
                  onChanged: (value) {
                    context.read<PlayerBloc>().add(
                      SeekSong(Duration(milliseconds: value.toInt())),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fmt(pos),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _p.textSecondary.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _fmt(dur),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _p.textSecondary.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Controls ────────────────────────────────────────────────
  Widget _buildControls(bool isPlaying, bool isBuffering) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () => context.read<PlayerBloc>().add(PreviousSong()),
            child: Container(
              width: 62,
              height: 62,
              decoration: _neuCircle(),
              child: Icon(
                Icons.skip_previous_rounded,
                color: _p.textPrimary,
                size: 28,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (isPlaying) {
                context.read<PlayerBloc>().add(PauseSong());
              } else {
                context.read<PlayerBloc>().add(ResumeSong());
              }
            },
            child: Container(
              width: 74,
              height: 74,
              decoration: _neuCircle(
                color: _p.surfaceLight,
                pressed: isPlaying,
              ),
              child: isBuffering
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: _p.textPrimary,
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: _p.textPrimary,
                      size: 34,
                    ),
            ),
          ),
          GestureDetector(
            onTap: () => context.read<PlayerBloc>().add(NextSong()),
            child: Container(
              width: 62,
              height: 62,
              decoration: _neuCircle(),
              child: Icon(
                Icons.skip_next_rounded,
                color: _p.textPrimary,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Playlist sheet ──────────────────────────────────────────
  void _showPlaylistSheet(PlayerState state) {
    final playlist = state.playlist;
    if (playlist.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: _p.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _p.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Text(
                    'Queue',
                    style: TextStyle(
                      color: _p.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${playlist.length} songs',
                    style: TextStyle(color: _p.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: playlist.length,
                itemBuilder: (_, index) {
                  final s = playlist[index];
                  final isCurrent = index == state.currentIndex;
                  return ListTile(
                    dense: true,
                    leading: isCurrent
                        ? Icon(
                            Icons.play_arrow_rounded,
                            color: _p.textPrimary,
                            size: 20,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: _p.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                    title: Text(
                      s.title,
                      style: TextStyle(
                        color: _p.textPrimary,
                        fontSize: 14,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      s.artist,
                      style: TextStyle(color: _p.textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      context.read<PlayerBloc>().add(
                        PlaySong(song: s, playlist: playlist),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Neumorphic helpers ──────────────────────────────────────
  BoxDecoration _neuRaised({double radius = 20, Color? color}) => BoxDecoration(
    color: color ?? _p.surface,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: _p.shadowDark,
        offset: const Offset(6, 6),
        blurRadius: 14,
      ),
      BoxShadow(
        color: _p.shadowLight,
        offset: const Offset(-4, -4),
        blurRadius: 10,
      ),
    ],
  );

  BoxDecoration _neuCircle({Color? color, bool pressed = false}) =>
      BoxDecoration(
        color: pressed ? _p.bg : (color ?? _p.surface),
        shape: BoxShape.circle,
        boxShadow: pressed
            ? [
                BoxShadow(
                  color: _p.shadowDark,
                  offset: const Offset(2, 2),
                  blurRadius: 5,
                  spreadRadius: -1,
                ),
                BoxShadow(
                  color: _p.shadowLight.withValues(alpha: 0.3),
                  offset: const Offset(-2, -2),
                  blurRadius: 5,
                  spreadRadius: -1,
                ),
              ]
            : [
                BoxShadow(
                  color: _p.shadowDark,
                  offset: const Offset(5, 5),
                  blurRadius: 12,
                ),
                BoxShadow(
                  color: _p.shadowLight,
                  offset: const Offset(-3, -3),
                  blurRadius: 10,
                ),
              ],
      );
}

// ═════════════════════════════════════════════════════════════════
//  TURNTABLE PAINTERS (always dark – physical hardware)
// ═════════════════════════════════════════════════════════════════

class _BasePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF222236), Color(0xFF1A1A2C), Color(0xFF1E1E30)],
        ).createShader(Offset.zero & size),
    );
    final cx = size.width * 0.38;
    final cy = size.height * 0.48;
    final pr = size.width * 0.36;
    canvas.drawCircle(
      Offset(cx, cy),
      pr,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.03)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      pr - 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.02)
        ..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VinylPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0xFF2A2A38),
            Color(0xFF1A1A24),
            Color(0xFF111118),
            Color(0xFF1A1A24),
            Color(0xFF0E0E16),
          ],
          stops: const [0, 0.25, 0.5, 0.75, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    for (var i = 0; i < 40; i++) {
      final gr = r * 0.24 + (r * 0.72) * (i / 40);
      canvas.drawCircle(
        c,
        gr,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withValues(alpha: i.isEven ? 0.035 : 0.015)
          ..strokeWidth = 0.35,
      );
    }

    canvas.drawPath(
      Path()..addArc(
        Rect.fromCircle(center: c, radius: r * 0.72),
        -pi * 0.8,
        pi * 0.4,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()..addArc(
        Rect.fromCircle(center: c, radius: r * 0.48),
        -pi * 0.6,
        pi * 0.25,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.035)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(c, r * 0.18, Paint()..color = const Color(0xFF3A3A4E));
    canvas.drawCircle(
      c,
      r * 0.18,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 0.5,
    );
    canvas.drawCircle(
      c,
      r * 0.12,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.04)
        ..strokeWidth = 0.4,
    );

    canvas.drawCircle(c, r * 0.04, Paint()..color = const Color(0xFFE0E0EC));
    canvas.drawCircle(c, r * 0.015, Paint()..color = const Color(0xFF1C1C28));

    canvas.drawCircle(
      c,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.05)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArmPainter extends CustomPainter {
  final double armPosition;
  _ArmPainter({required this.armPosition});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pivot = Offset(w * 0.6, h * 0.08);

    canvas.drawCircle(pivot, 15, Paint()..color = const Color(0xFF2E2E42));
    canvas.drawCircle(
      pivot,
      15,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 0.5,
    );
    canvas.drawCircle(pivot, 4.5, Paint()..color = const Color(0xFF3E3E56));
    canvas.drawCircle(
      pivot,
      2,
      Paint()..color = Colors.white.withValues(alpha: 0.1),
    );

    final angle = 0.3 - (armPosition * 0.2);
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final arm = Paint()
      ..color = const Color(0xFF4A4A62)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(2, 0), Offset(2, h * 0.5), shadow);
    canvas.drawLine(Offset(2, h * 0.5), Offset(-w * 0.2 + 2, h * 0.68), shadow);

    canvas.drawLine(Offset.zero, Offset(0, h * 0.5), arm);
    canvas.drawLine(Offset(0, h * 0.5), Offset(-w * 0.2, h * 0.68), arm);

    final head = Offset(-w * 0.2, h * 0.68);
    canvas.drawRect(
      Rect.fromCenter(center: head, width: 9, height: 15),
      Paint()..color = const Color(0xFF3A3A50),
    );
    canvas.drawRect(
      Rect.fromCenter(center: head + const Offset(0, 9), width: 5, height: 5),
      Paint()..color = const Color(0xFF555570),
    );
    canvas.drawLine(
      head + const Offset(0, 11),
      head + const Offset(0, 14),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      Offset(0, -h * 0.015),
      8,
      Paint()..color = const Color(0xFF3A3A4E),
    );
    canvas.drawCircle(
      Offset(0, -h * 0.015),
      8,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.05)
        ..strokeWidth = 0.5,
    );

    canvas.restore();

    final rx = w * 0.88;
    final ry = h * 0.46;
    canvas.drawLine(
      Offset(rx, ry - 12),
      Offset(rx, ry + 12),
      Paint()
        ..color = const Color(0xFF3E3E56)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(rx, ry - 14),
      4.5,
      Paint()..color = const Color(0xFF4A4A62),
    );
  }

  @override
  bool shouldRepaint(covariant _ArmPainter old) =>
      old.armPosition != armPosition;
}

class _ScrewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.28;
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.6;
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), p);
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
