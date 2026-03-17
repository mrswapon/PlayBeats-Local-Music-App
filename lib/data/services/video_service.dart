import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:play_beats/data/models/video_model.dart';
import 'package:play_beats/data/services/hive_service.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

// Helper function that works in both debug and release
void logMessage(String message) {
  if (kDebugMode) {
    debugPrint(message);
  } else {
    developer.log(message, name: 'VideoService');
  }
}

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
      logMessage('Requesting video permissions...');
      
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        logMessage('Android SDK: $sdkInt');

        // For Android 11+ (API 30+), request MANAGE_EXTERNAL_STORAGE
        if (sdkInt >= 30) {
          var status = await Permission.manageExternalStorage.status;
          logMessage('MANAGE_EXTERNAL_STORAGE status: ${status.name}');
          
          if (status.isGranted) {
            logMessage('MANAGE_EXTERNAL_STORAGE already granted');
            return true;
          }

          // Request the permission
          logMessage('Requesting MANAGE_EXTERNAL_STORAGE...');
          status = await Permission.manageExternalStorage.request();
          logMessage('MANAGE_EXTERNAL_STORAGE after request: ${status.name}');
          
          if (status.isGranted) {
            return true;
          }

          // Fallback to videos permission
          var videoStatus = await Permission.videos.status;
          logMessage('Videos permission status: ${videoStatus.name}');
          
          if (videoStatus.isGranted) return true;
          
          videoStatus = await Permission.videos.request();
          logMessage('Videos after request: ${videoStatus.name}');
          
          return videoStatus.isGranted;
        }

        // For Android 12 and below
        var storageStatus = await Permission.storage.status;
        logMessage('Storage permission status: ${storageStatus.name}');
        
        if (storageStatus.isGranted) return true;

        storageStatus = await Permission.storage.request();
        logMessage('Storage after request: ${storageStatus.name}');
        
        if (storageStatus.isGranted) return true;

        // Fallback to videos permission
        var videoStatus = await Permission.videos.status;
        if (videoStatus.isGranted) return true;

        videoStatus = await Permission.videos.request();
        logMessage('Videos permission: ${videoStatus.name}');
        
        return videoStatus.isGranted;
      }
      
      logMessage('Not Android, returning true');
      return true;
    } catch (e, stackTrace) {
      logMessage('Permission error: $e');
      logMessage('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get all videos with caching - OPTIMIZED FOR SPEED
  Future<List<Video>> getAllVideos() async {
    final stopwatch = Stopwatch()..start();
    logMessage('=== getAllVideos START ===');
    
    try {
      // Return cached videos if available and fresh (< 24 hours)
      if (_cachedVideos != null && _cacheTimestamp != null) {
        if (DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
          logMessage('Returning ${_cachedVideos!.length} cached videos (${stopwatch.elapsedMilliseconds}ms)');
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
              logMessage('Loaded ${_cachedVideos!.length} videos from Hive (${stopwatch.elapsedMilliseconds}ms)');
              return _cachedVideos!;
            }
          }
        }
      } catch (e) {
        logMessage('Cache load error: $e');
      }

      // Scan for videos using optimized parallel processing
      logMessage('Scanning for videos (optimized)...');
      final videos = await _scanVideosFast();
      logMessage('Found ${videos.length} videos in ${stopwatch.elapsedMilliseconds}ms');

      // Cache the results
      _cachedVideos = videos;
      _cacheTimestamp = DateTime.now();

      // Save to Hive (async, don't wait)
      unawaited(_saveToCache(stopwatch.elapsedMilliseconds));

      return videos;
    } catch (e, stackTrace) {
      logMessage('Error in getAllVideos: $e');
      logMessage('Stack: $stackTrace');
      return [];
    }
  }

  /// Save to cache asynchronously
  Future<void> _saveToCache(int scanTime) async {
    try {
      if (_cachedVideos == null || _cacheTimestamp == null) return;
      
      final box = await HiveService.settingsBox;
      await box.put(_lastScanKey, _cacheTimestamp!.millisecondsSinceEpoch);
      final encoded = jsonEncode(_cachedVideos!.map((v) => v.toJson()).toList());
      await box.put(_videosCacheKey, encoded);
      logMessage('Cached ${_cachedVideos!.length} videos to Hive (total: ${scanTime}ms)');
    } catch (e) {
      logMessage('Cache save error: $e');
    }
  }

  /// Scan directories for video files - OPTIMIZED (parallel processing)
  Future<List<Video>> _scanVideosFast() async {
    final stopwatch = Stopwatch()..start();
    final videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm'];
    final videos = <Video>[];
    final externalStorage = Directory('/storage/emulated/0');

    if (!await externalStorage.exists()) {
      return videos;
    }

    // Only scan most common directories for speed
    final directoriesToScan = [
      'DCIM/Camera',
      'DCIM',
      'Movies',
      'Download',
      'Videos',
    ];

    final fileFutures = <Future<List<File>>>[];

    // Start scanning directories in parallel
    for (final dirName in directoriesToScan) {
      try {
        final dirPath = '${externalStorage.path}/$dirName';
        final directory = Directory(dirPath);

        if (await directory.exists()) {
          fileFutures.add(_scanDirectory(directory, videoExtensions));
        }
      } catch (e) {
        logMessage('Error accessing $dirName: $e');
      }
    }

    // Wait for all directory scans to complete
    final results = await Future.wait(fileFutures);
    
    // Combine all files
    final allFiles = <File>[];
    for (final result in results) {
      allFiles.addAll(result);
    }

    logMessage('Found ${allFiles.length} video files in ${stopwatch.elapsedMilliseconds}ms');

    // Process files - create Video objects without duration (faster)
    for (final file in allFiles) {
      try {
        final fileName = file.path.split('/').last;
        final title = fileName.replaceAll('_', ' ').replaceAll(RegExp(r'\.[^.]+$'), '');
        
        // Determine album from path
        String album = 'Unknown';
        for (final dir in directoriesToScan) {
          if (file.path.contains(dir)) {
            album = dir.split('/').first;
            break;
          }
        }

        videos.add(Video(
          id: file.path.hashCode.toString(),
          title: title,
          artist: 'Unknown',
          filePath: file.path,
          duration: 0, // Will be loaded when played
          album: album,
          albumId: album.hashCode,
          thumbnailPath: null, // Lazy load thumbnails
        ));
      } catch (e) {
        logMessage('Error processing ${file.path}: $e');
      }
    }

    videos.sort((a, b) => a.title.compareTo(b.title));
    logMessage('Processed ${videos.length} videos in ${stopwatch.elapsedMilliseconds}ms');
    return videos;
  }

  /// Scan a single directory for video files
  Future<List<File>> _scanDirectory(Directory directory, List<String> extensions) async {
    final files = <File>[];
    try {
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            final ext = entity.path.toLowerCase().split('.').last;
            if (extensions.contains(ext)) {
              final stat = await entity.stat();
              // Only include files larger than 1MB
              if (stat.size > 1000000) {
                files.add(entity);
              }
            }
          } catch (e) {
            // Skip files we can't access
          }
        }
      }
    } catch (e) {
      logMessage('Error scanning ${directory.path}: $e');
    }
    return files;
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
      logMessage('Error generating thumbnail: $e');
      return null;
    }
  }

  /// Get video duration on-demand (fast, with caching)
  Future<int> getVideoDuration(String filePath) async {
    // Check in-memory cache first
    final cached = _metadataCache[filePath];
    if (cached != null) {
      return cached.duration;
    }

    try {
      final controller = VideoPlayerController.file(File(filePath));
      await controller.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () => logMessage('Duration timeout: $filePath'),
      );

      if (!controller.value.isInitialized) {
        final duration = await _estimateDurationFromSize(filePath);
        _cacheMetadata(filePath, 'Unknown', duration);
        controller.dispose();
        return duration;
      }

      final duration = controller.value.duration.inMilliseconds;
      _cacheMetadata(filePath, 'Unknown', duration);
      await controller.dispose();
      return duration;
    } catch (e) {
      logMessage('Error getting duration: $e');
      final duration = await _estimateDurationFromSize(filePath);
      _cacheMetadata(filePath, 'Unknown', duration);
      return duration;
    }
  }

  /// Estimate duration from file size (fallback)
  Future<int> _estimateDurationFromSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final size = await file.length();
        // Rough estimate: ~0.75MB/min = 12.5KB/sec
        final estimatedMs = ((size / 12500) * 1000).round();
        return estimatedMs;
      }
    } catch (_) {}
    return 0;
  }

  /// Cache video metadata
  void _cacheMetadata(String path, String title, int duration) {
    if (_metadataCache.length >= 200) {
      _metadataCache.remove(_metadataCache.keys.first);
    }
    _metadataCache[path] = _VideoMetadata(
      title: title,
      duration: duration,
      timestamp: DateTime.now(),
    );
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
