import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:play_beats/core/theme/app_theme.dart';
import 'package:play_beats/data/models/video_model.dart';
import 'package:play_beats/data/services/video_player_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Video video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerService _videoPlayerService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _videoPlayerService = VideoPlayerService();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      await _videoPlayerService.initialize(widget.video.filePath);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video player
          Center(
            child: _isInitialized &&
                    _videoPlayerService.chewieController != null
                ? Chewie(
                    controller: _videoPlayerService.chewieController!,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: c.accent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading video...',
                        style: TextStyle(color: c.textSecondary),
                      ),
                    ],
                  ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.video.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.video.artist,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
