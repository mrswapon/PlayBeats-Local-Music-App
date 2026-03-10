import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:play_beats/core/theme/app_theme.dart';
import 'package:play_beats/core/theme/neumorphic.dart';
import 'package:play_beats/data/services/audio_player_service.dart';
import 'package:play_beats/features/player/bloc/player_bloc.dart';
import 'package:play_beats/features/player/bloc/player_event.dart';
import 'package:play_beats/features/player/bloc/player_state.dart';
import 'package:play_beats/features/player/screens/player_screen.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;
  bool _wasVisible = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnim = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    );

    final state = context.read<PlayerBloc>().state;
    final visible = state is! PlayerStopped && state.currentSong != null;
    if (visible) {
      _slideController.value = 1.0;
      _wasVisible = true;
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocConsumer<PlayerBloc, PlayerState>(
      listener: (context, state) {
        final visible = state is! PlayerStopped && state.currentSong != null;
        if (visible && !_wasVisible) {
          _slideController.forward();
        } else if (!visible && _wasVisible) {
          _slideController.reverse();
        }
        _wasVisible = visible;
      },
      builder: (context, state) {
        if ((state is PlayerStopped || state.currentSong == null) &&
            _slideController.isDismissed) {
          return const SizedBox.shrink();
        }

        final song = state.currentSong;
        if (song == null) return const SizedBox.shrink();

        final isPlaying = state is PlayerPlaying;
        final audioService = context.read<AudioPlayerService>();

        return SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlayerScreen()),
              ),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: Neu.raised(
                  radius: 22,
                  color: c.surface,
                  shadowDark: c.shadowDark,
                  shadowLight: c.shadowLight,
                ),
                child: Row(
                  children: [
                    // ── Album art with arc progress ──
                    StreamBuilder<Duration>(
                      stream: audioService.player.positionStream,
                      builder: (context, snapshot) {
                        final pos = snapshot.data ?? Duration.zero;
                        final dur =
                            audioService.player.duration ?? Duration.zero;
                        final progress = dur.inMilliseconds > 0
                            ? (pos.inMilliseconds / dur.inMilliseconds)
                                .clamp(0.0, 1.0)
                            : 0.0;

                        return SizedBox(
                          width: 46,
                          height: 46,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(46, 46),
                                painter: ArcProgressPainter(
                                  progress: progress,
                                  strokeWidth: 3,
                                  color: c.accent,
                                  bgColor: c.background,
                                ),
                              ),
                              ClipOval(
                                child: QueryArtworkWidget(
                                  id: song.numericId,
                                  type: ArtworkType.AUDIO,
                                  artworkWidth: 36,
                                  artworkHeight: 36,
                                  artworkBorder: BorderRadius.circular(18),
                                  artworkFit: BoxFit.cover,
                                  nullArtworkWidget: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: c.surfaceLight,
                                    ),
                                    child: Icon(
                                      Icons.music_note_rounded,
                                      size: 16,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),

                    // ── Title & artist ──
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ── Play/pause ──
                    GestureDetector(
                      onTap: () {
                        if (isPlaying) {
                          context.read<PlayerBloc>().add(PauseSong());
                        } else {
                          context.read<PlayerBloc>().add(ResumeSong());
                        }
                      },
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: c.textPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // ── Next ──
                    GestureDetector(
                      onTap: () =>
                          context.read<PlayerBloc>().add(NextSong()),
                      child: Icon(
                        Icons.skip_next_rounded,
                        color: c.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
