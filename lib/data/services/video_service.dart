import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class VideoFile {
  final String id;
  final String title;
  final String artist;
  final String filePath;
  final int duration;
  final String album;
  final int albumId;

  VideoFile({
    required this.id,
    required this.title,
    required this.artist,
    required this.filePath,
    this.duration = 0,
    this.album = '',
    this.albumId = 0,
  });
}

class VideoService {
  /// Request storage permission for accessing video files.
  Future<bool> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        // Check storage permission for Android 12 and below
        var status = await Permission.storage.status;
        if (status.isGranted) return true;
        
        status = await Permission.storage.request();
        if (status.isGranted) return true;
        
        // For Android 13+, also try media permission
        status = await Permission.videos.status;
        if (status.isGranted) return true;
        
        status = await Permission.videos.request();
        return status.isGranted;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all video files from external storage.
  Future<List<VideoFile>> getAllVideos() async {
    try {
      final videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm'];
      final videos = <VideoFile>[];
      
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
                      videos.add(VideoFile(
                        id: entity.path.hashCode.toString(),
                        title: entity.path.split('/').last.replaceAll('_', ' ').replaceAll('.$ext', ''),
                        artist: 'Unknown',
                        filePath: entity.path,
                        duration: 0,
                        album: dirName,
                        albumId: dirName.hashCode,
                      ));
                    }
                  } catch (e) {
                    // Skip files we can't access
                  }
                }
              }
            }
          }
        } catch (e) {
          // Skip directories we can't access
        }
      }

      // Sort by title
      videos.sort((a, b) => a.title.compareTo(b.title));
      return videos;
    } catch (e) {
      return [];
    }
  }
}
