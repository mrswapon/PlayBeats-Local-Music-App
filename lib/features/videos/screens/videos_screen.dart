import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/core/theme/app_theme.dart';
import 'package:play_beats/core/theme/neumorphic.dart';
import 'package:play_beats/data/models/video_model.dart';
import 'package:play_beats/features/videos/bloc/videos_bloc.dart';
import 'package:play_beats/features/videos/bloc/videos_event.dart';
import 'package:play_beats/features/videos/bloc/videos_state.dart';
import 'package:play_beats/features/videos/screens/video_player_screen.dart';
import 'package:shimmer/shimmer.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    context.read<VideosBloc>().add(LoadVideos());
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0A0A18), Color(0xFF0F0F22), Color(0xFF131330)]
              : const [Color(0xFFE0E0EC), Color(0xFFE8E8F4), Color(0xFFF0F0FC)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
              child: Row(
                children: [
                  Text(
                    'Videos',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  // Refresh button
                  GestureDetector(
                    onTap: () {
                      context.read<VideosBloc>().add(RefreshVideos());
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.04),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Icon(Icons.refresh_rounded,
                          color: c.iconDim, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Content
            Expanded(
              child: BlocConsumer<VideosBloc, VideosState>(
                listener: (context, state) {
                  if (state is VideosLoaded) {
                    _entryController.reset();
                    _entryController.forward();
                  }
                },
                builder: (context, state) {
                  if (state is VideosLoading) {
                    return _buildShimmer();
                  }

                  if (state is VideosPermissionDenied) {
                    return _buildPermissionDenied();
                  }

                  if (state is VideosError) {
                    return _buildError(state.message);
                  }

                  if (state is VideosLoaded) {
                    if (state.videos.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildVideoList(state.videos);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoList(List<Video> videos) {
    return RefreshIndicator(
      color: context.colors.textPrimary,
      backgroundColor: context.colors.surface,
      onRefresh: () async {
        context.read<VideosBloc>().add(RefreshVideos());
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final delay = index * 0.06;
          final start = (0.1 + delay).clamp(0.0, 0.95);
          final end = (start + 0.35).clamp(0.0, 1.0);

          return FadeTransition(
            opacity: CurvedAnimation(
              parent: _entryController,
              curve: Interval(start, end, curve: Curves.easeOut),
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.45, 0.35),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _entryController,
                curve: Interval(start, end, curve: Curves.easeOutCubic),
              )),
              child: _buildVideoTile(videos[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoTile(Video video) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(video: video),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: Neu.raised(
            radius: 18,
            color: c.surface,
            shadowDark: c.shadowDark,
            shadowLight: c.shadowLight,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 140,
                  height: 78,
                  color: c.background,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Icon(
                        Icons.video_library,
                        size: 40,
                        color: c.iconDim,
                      ),
                      // Duration badge
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.durationFormatted,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // Play overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: c.accent.withValues(alpha: 0.0),
                          ),
                          child: const Icon(
                            Icons.play_circle_filled,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Video info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.artist,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (video.album.isNotEmpty &&
                        video.album != 'Unknown Album') ...[
                      const SizedBox(height: 4),
                      Text(
                        video.album,
                        style: TextStyle(
                          color: c.iconDim,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    final c = context.colors;
    final base = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1C1C34)
        : const Color(0xFFD4D4E0);
    final highlight = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF282848)
        : const Color(0xFFE8E8F4);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 6,
        itemBuilder: (_, __) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 78,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 10,
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: Neu.circular(
              color: c.surface,
              bgColor: c.background,
              shadowDark: c.shadowDark,
              shadowLight: c.shadowLight,
            ),
            child: Icon(Icons.video_library_rounded,
                color: c.iconDim, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'No videos found',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add video files to your device\nto see them here',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off_rounded,
              size: 64, color: c.iconDim.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text('Permission Required',
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('PlayBeats needs access to your\nvideo files to play videos',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              context.read<VideosBloc>().add(LoadVideos());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: (isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.04))
                    .withValues(alpha: 0.06),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, color: c.textPrimary, size: 18),
                  const SizedBox(width: 8),
                  Text('Retry',
                      style: TextStyle(
                          color: c.textPrimary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 64, color: c.iconDim.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text('Something went wrong',
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              context.read<VideosBloc>().add(LoadVideos());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: (isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.04))
                    .withValues(alpha: 0.06),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, color: c.textPrimary, size: 18),
                  const SizedBox(width: 8),
                  Text('Retry',
                      style: TextStyle(
                          color: c.textPrimary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
