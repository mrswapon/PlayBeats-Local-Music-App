import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/core/theme/app_theme.dart';
import 'package:play_beats/core/theme/neumorphic.dart';
import 'package:play_beats/data/services/audio_player_service.dart';
import 'package:play_beats/features/player/bloc/player_bloc.dart';
import 'package:play_beats/features/player/bloc/player_event.dart';
import 'package:play_beats/features/player/bloc/player_state.dart';
import 'package:play_beats/features/player/screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        if (state is PlayerStopped || state.currentSong == null) {
          return const SizedBox.shrink();
        }

        final song = state.currentSong!;
        final isPlaying = state is PlayerPlaying;
        final audioService = context.read<AudioPlayerService>();

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlayerScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: Neu.raised(
              radius: 22,
              color: c.surface,
              shadowDark: c.shadowDark,
              shadowLight: c.shadowLight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${song.title} - ${song.artist}',
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                        color: c.textSecondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
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
                const SizedBox(height: 10),
                // Progress bar
                StreamBuilder<Duration>(
                  stream: audioService.player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration =
                        audioService.player.duration ?? Duration.zero;
                    final progress = duration.inMilliseconds > 0
                        ? (position.inMilliseconds / duration.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0.0;

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: c.background,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(c.accent),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
