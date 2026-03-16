import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:play_beats/data/models/video_model.dart';
import 'package:play_beats/data/services/hive_service.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoService {
  static const String _lastScanKey = 'last_scan_time';
  static const String _videosCacheKey = 'videos_data';
  static const Duration _cacheDuration = Duration(hours: 24);
  
  // In-memory cache for quick access
  final Map<String, _VideoMetadata> _metadataCache = {};
  List<Video>? _cachedVideos;
  DateTime? _cacheTimestamp;

  /// Request storage permission for accessing video files.
  Future<bool> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.videos.status;
        if (status.isGranted) return true;
        status = await Permission.videos.request();
        return status.isGranted;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all videos with caching
  Future<List<Video>> getAllVideos() async {
    // Return cached videos if available and fresh (< 24 hours)
    if (_cachedVideos != null && _cacheTimestamp != null) {
      if (DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
        debugPrint('Returning cached videos (${_cachedVideos!.length} items)');
        return _cachedVideos!;
      }
    }

    // Try to load from Hive cache
    try {
      final box = await HiveService.settingsBox;
      final lastScan = box.get(_lastScanKey);
      if (lastScan != null) {
        final scanTime = DateTime.fromMillisecondsSinceEpoch(lastScan);
        if (DateTime.now().difference(scanTime) < _cacheDuration) {
          final cachedData = box.get(_videosCacheKey);
          if (cachedData != null && cachedData is String) {
            final List<dynamic> decoded = jsonDecode(cachedData);
            _cachedVideos = decoded.map((d) => Video.fromJson(d)).toList();
            _cacheTimestamp = scanTime;
            debugPrint('Loaded ${_cachedVideos!.length} videos from Hive cache');
            return _cachedVideos!;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading video cache: $e');
    }

    // Scan for videos
    debugPrint('Scanning for videos...');
    final videos = await _scanVideos();
    
    // Cache the results
    _cachedVideos = videos;
    _cacheTimestamp = DateTime.now();
    
    // Save to Hive
    try {
      final box = await HiveService.settingsBox;
      await box.put(_lastScanKey, _cacheTimestamp!.millisecondsSinceEpoch);
      final encoded = jsonEncode(videos.map((v) => v.toJson()).toList());
      await box.put(_videosCacheKey, encoded);
      debugPrint('Cached ${videos.length} videos to Hive');
    } catch (e) {
      debugPrint('Error saving video cache: $e');
    }

    return videos;
  }

  /// Scan directories for video files
  Future<List<Video>> _scanVideos() async {
    final videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm'];
    final videos = <Video>[];
    final externalStorage = Directory('/storage/emulated/0');

    if (!await externalStorage.exists()) {
      return videos;
    }

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
                  // Only include files larger than 1MB
                  if (stat.size > 1000000) {
                    final cached = _metadataCache[entity.path];
                    int duration;
                    String title;
                    
                    if (cached != null) {
                      duration = cached.duration;
                      title = cached.title;
                    } else {
                      duration = await _getVideoDuration(entity.path);
                      title = entity.path.split('/').last.replaceAll('_', ' ').replaceAll('.$ext', '');
                      _cacheMetadata(entity.path, title, duration);
                    }

                    videos.add(Video(
                      id: entity.path.hashCode.toString(),
                      title: title,
                      artist: 'Unknown',
                      filePath: entity.path,
                      duration: duration,
                      album: dirName,
                      albumId: dirName.hashCode,
                      thumbnailPath: null,
                    ));
                  }
                } catch (e) {
                  debugPrint('Error processing video ${entity.path}: $e');
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error accessing directory $dirName: $e');
      }
    }

    videos.sort((a, b) => a.title.compareTo(b.title));
    return videos;
  }

  /// Cache video metadata
  void _cacheMetadata(String path, String title, int duration) {
    if (_metadataCache.length >= 100) {
      _metadataCache.remove(_metadataCache.keys.first);
    }
    _metadataCache[path] = _VideoMetadata(
      title: title,
      duration: duration,
      timestamp: DateTime.now(),
    );
  }

  /// Generate thumbnail for video on-demand
  Future<String?> generateThumbnail(String filePath) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: filePath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 320,
        quality: 80,
      );
      return thumbnailPath;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }

  /// Extract video duration with timeout
  Future<int> _getVideoDuration(String filePath) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(File(filePath));
      await controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () => debugPrint('Timeout: $filePath'),
      );
      
      if (!controller.value.isInitialized) {
        return await _estimateDurationFromSize(filePath);
      }
      
      return controller.value.duration.inMilliseconds;
    } catch (e) {
      debugPrint('Error getting duration: $e');
      return await _estimateDurationFromSize(filePath);
    } finally {
      controller?.dispose();
    }
  }

  /// Estimate duration from file size
  Future<int> _estimateDurationFromSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final size = await file.length();
        final estimatedMs = ((size / 12500) * 1000).round();
        return estimatedMs;
      }
    } catch (_) {}
    return 0;
  }

  /// Clear video cache (for manual refresh)
  Future<void> clearCache() async {
    _cachedVideos = null;
    _cacheTimestamp = null;
    _metadataCache.clear();
    try {
      final box = await HiveService.settingsBox;
      await box.delete(_lastScanKey);
      await box.delete(_videosCacheKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}

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
