import 'dart:io';

import 'package:on_audio_query/on_audio_query.dart';

class VideoService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Request the appropriate permission for video files.
  Future<bool> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        // First check if already granted
        final permission = await _audioQuery.permissionsStatus();
        if (permission) return true;

        // Request permission using on_audio_query (handles request codes properly)
        final granted = await _audioQuery.permissionsRequest();
        if (granted) return true;

        // Double check after request
        return await _audioQuery.permissionsStatus();
      }
      return true;
    } catch (e) {
      // If permission request fails, assume denied
      return false;
    }
  }

  /// Get all songs on the device (we'll filter for video files by extension).
  Future<List<SongModel>> getAllVideos() async {
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    // Filter for video file extensions
    final videoExtensions = ['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv'];
    return songs
        .where((s) {
          final ext = s.data.toLowerCase().split('.').last;
          return videoExtensions.any((ve) => '.$ext'.contains(ve));
        })
        .toList();
  }
}
