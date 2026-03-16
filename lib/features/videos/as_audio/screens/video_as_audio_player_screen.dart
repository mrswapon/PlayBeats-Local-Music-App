import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:play_beats/data/models/video_model.dart';
import 'package:play_beats/data/services/audio_player_service.dart';
import 'package:play_beats/features/videos/as_audio/bloc/video_as_audio_bloc.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoAsAudioPlayerScreen extends StatefulWidget {
  final Video video;
  final List<Video> playlist;

  const VideoAsAudioPlayerScreen({
    super.key,
    required this.video,
    this.playlist = const [],
  });

  @override
  State<VideoAsAudioPlayerScreen> createState() => _VideoAsAudioPlayerScreenState();
}

class _VideoAsAudioPlayerScreenState extends State<VideoAsAudioPlayerScreen> {
  String? _thumbnailPath;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
    context.read<VideoAsAudioBloc>().add(
      PlayVideoAsAudio(video: widget.video, playlist: widget.playlist),
    );
  }

  Future<void> _loadThumbnail() async {
    final path = await VideoThumbnail.thumbnailFile(
      video: widget.video.filePath,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 400,
      quality: 85,
    );
    if (mounted) {
      setState(() => _thumbnailPath = path);
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 28),
                    onPressed: () => Navigator.pop(context),
                    color: textColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Now Playing',
                          style: TextStyle(color: subTextColor, fontSize: 12),
                        ),
                        Text(
                          'Video as Audio',
                          style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const Spacer(),

            // Album art / Thumbnail
            BlocBuilder<VideoAsAudioBloc, VideoAsAudioState>(
              builder: (context, state) {
                final video = state.currentVideo ?? widget.video;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: _thumbnailPath != null && _thumbnailPath!.isNotEmpty
                            ? Image.file(
                                File(_thumbnailPath!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildPlaceholder(video, subTextColor),
                              )
                            : _buildPlaceholder(video, subTextColor),
                      ),
                    ),
                  ),
                );
              },
            ),

            const Spacer(),

            // Video info
            BlocBuilder<VideoAsAudioBloc, VideoAsAudioState>(
              builder: (context, state) {
                final video = state.currentVideo ?? widget.video;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        video.displayTitle,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        video.artist,
                        style: TextStyle(color: subTextColor, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Progress bar
            BlocBuilder<VideoAsAudioBloc, VideoAsAudioState>(
              builder: (context, state) {
                final service = context.read<AudioPlayerService>();
                final videoDuration = state.currentVideo?.duration ?? 0;
                return StreamBuilder(
                  stream: service.player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = Duration(milliseconds: videoDuration is int ? videoDuration : (videoDuration as num).toInt());
                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            activeTrackColor: accentColor,
                            inactiveTrackColor: subTextColor.withValues(alpha: 0.2),
                            thumbColor: accentColor,
                          ),
                          child: Slider(
                            value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble()),
                            max: duration.inMilliseconds.toDouble(),
                            onChanged: (value) {
                              context.read<VideoAsAudioBloc>().add(
                                SeekVideoAsAudio(Duration(milliseconds: value.toInt())),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(position), style: TextStyle(color: subTextColor, fontSize: 12)),
                              Text(_formatDuration(duration), style: TextStyle(color: subTextColor, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // Controls
            BlocBuilder<VideoAsAudioBloc, VideoAsAudioState>(
              builder: (context, state) {
                final isPlaying = state is VideoAsAudioPlaying;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle),
                        iconSize: 24,
                        color: state.shuffleEnabled ? accentColor : subTextColor,
                        onPressed: () {
                          context.read<VideoAsAudioBloc>().add(ToggleShuffleVideoAsAudio());
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 36,
                        color: textColor,
                        onPressed: () {
                          context.read<VideoAsAudioBloc>().add(PreviousVideoAsAudio());
                        },
                      ),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                          iconSize: 36,
                          color: Colors.white,
                          onPressed: () {
                            if (isPlaying) {
                              context.read<VideoAsAudioBloc>().add(PauseVideoAsAudio());
                            } else {
                              context.read<VideoAsAudioBloc>().add(ResumeVideoAsAudio());
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        iconSize: 36,
                        color: textColor,
                        onPressed: () {
                          context.read<VideoAsAudioBloc>().add(NextVideoAsAudio());
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.repeat),
                        iconSize: 24,
                        color: subTextColor,
                        onPressed: () {
                          // Could add repeat functionality
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Video video, Color subTextColor) {
    return Container(
      color: subTextColor.withValues(alpha: 0.1),
      child: Icon(Icons.video_library, size: 80, color: subTextColor),
    );
  }
}
