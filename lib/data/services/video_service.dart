import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:play_beats/data/models/video_model.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoService {
  // Cache for video metadata to avoid re-scanning
  final Map<String, _VideoMetadata> _metadataCache = {};
  static const int _cacheMaxSize = 100;

  /// Request storage permission for accessing video files.
  Future<bool> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        // For Android 11+ (API 30+), request MANAGE_EXTERNAL_STORAGE
        if (sdkInt >= 30) {
          var status = await Permission.manageExternalStorage.status;
          if (status.isGranted) return true;

          // Request the permission
          status = await Permission.manageExternalStorage.request();
          if (status.isGranted) return true;

          // If denied, try videos permission as fallback
          status = await Permission.videos.status;
          if (status.isGranted) return true;

          status = await Permission.videos.request();
          return status.isGranted;
        }

        // For Android 12 and below, use storage permission
        var storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) return true;

        storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) return true;

        // Also try videos permission
        var videoStatus = await Permission.videos.status;
        if (videoStatus.isGranted) return true;

        videoStatus = await Permission.videos.request();
        return videoStatus.isGranted;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all video files from external storage with thumbnails and duration.
  /// Uses lazy loading - thumbnails generated on-demand.
  Future<List<Video>> getAllVideos() async {
    try {
      final videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm'];
      final videos = <Video>[];

      // Primary external storage directory
      final externalStorage = Directory('/storage/emulated/0');

      if (!await externalStorage.exists()) {
        return videos;
      }

      // Scan common directories
      final directoriesToScan = [
        'DCIM',
        'Movies',
        'Download',
        'Videos',
        'WhatsApp/Media',
        'Telegram/Telegram Video',
      ];

      for (final dirName in directoriesToScan) {
        try {
          final dirPath = '${externalStorage.path}/$dirName';
          final directory = Directory(dirPath);

          if (await directory.exists()) {
            final entities = await directory
                .list(recursive: true, followLinks: false)
                .toList();

            for (final entity in entities) {
              if (entity is File) {
                final ext = entity.path.toLowerCase().split('.').last;
                if (videoExtensions.contains(ext)) {
                  try {
                    final stat = await entity.stat();
                    // Only include files larger than 1MB (filter out thumbnails)
                    if (stat.size > 1000000) {
                      // Check cache first
                      final cached = _metadataCache[entity.path];
                      if (cached != null) {
                        videos.add(Video(
                          id: entity.path.hashCode.toString(),
                          title: cached.title,
                          artist: 'Unknown',
                          filePath: entity.path,
                          duration: cached.duration,
                          album: dirName,
                          albumId: dirName.hashCode,
                          thumbnailPath: null, // Lazy load thumbnails
                        ));
                      } else {
                        // Get duration only - thumbnail lazy-loaded
                        final duration = await _getVideoDuration(entity.path);
                        final title = entity.path.split('/').last.replaceAll('_', ' ').replaceAll('.$ext', '');
                        
                        // Cache metadata
                        _cacheMetadata(entity.path, title, duration);
                        
                        videos.add(Video(
                          id: entity.path.hashCode.toString(),
                          title: title,
                          artist: 'Unknown',
                          filePath: entity.path,
                          duration: duration,
                          album: dirName,
                          albumId: dirName.hashCode,
                          thumbnailPath: null, // Lazy load thumbnails on-demand
                        ));
                      }
                    }
                  } catch (e) {
                    // Skip files we can't process
                    debugPrint('Error processing video ${entity.path}: $e');
                  }
                }
              }
            }
          }
        } catch (e) {
          // Skip directories we can't access
          debugPrint('Error accessing directory $dirName: $e');
        }
      }

      // Sort by title
      videos.sort((a, b) => a.title.compareTo(b.title));
      return videos;
    } catch (e) {
      debugPrint('Error getting videos: $e');
      return [];
    }
  }

  /// Cache video metadata
  void _cacheMetadata(String path, String title, int duration) {
    if (_metadataCache.length >= _cacheMaxSize) {
      // Remove oldest entry
      _metadataCache.remove(_metadataCache.keys.first);
    }
    _metadataCache[path] = _VideoMetadata(
      title: title,
      duration: duration,
      timestamp: DateTime.now(),
    );
  }

  /// Generate thumbnail for video on-demand (lazy loading)
  Future<String?> generateThumbnail(String filePath) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: filePath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 320, // Higher quality for better UX
        quality: 80,
      );
      return thumbnailPath;
    } catch (e) {
      debugPrint('Error generating thumbnail for $filePath: $e');
      return null;
    }
  }

  /// Extract video duration using video_player
  Future<int> _getVideoDuration(String filePath) async {
    try {
      final controller = VideoPlayerController.file(File(filePath));
      await controller.initialize();
      final duration = controller.value.duration.inMilliseconds;
      await controller.dispose();
      return duration;
    } catch (e) {
      debugPrint('Error getting duration for $filePath: $e');
      return 0;
    }
  }
}

/// Helper class for cached video metadata
class _VideoMetadata {
  final String title;
  final int duration;
  final DateTime timestamp;

  _VideoMetadata({
    required this.title,
    required this.duration,
    required this.timestamp,
  });
}
