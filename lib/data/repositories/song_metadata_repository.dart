import 'package:play_beats/data/models/song_model.dart';
import 'package:play_beats/data/services/hive_service.dart';

/// Repository for managing song metadata overrides (custom titles, etc.)
/// Stores user customizations in Hive separately from the original file metadata.
class SongMetadataRepository {

  /// Get custom title for a song
  String? getCustomTitle(String songId) {
    try {
      final box = HiveService.settingsBox;
      return box.get('custom_title_$songId');
    } catch (e) {
      return null;
    }
  }

  /// Set custom title for a song
  Future<void> setCustomTitle(String songId, String? customTitle) async {
    try {
      final box = HiveService.settingsBox;
      if (customTitle == null || customTitle.isEmpty) {
        // Remove custom title if empty
        await box.delete('custom_title_$songId');
      } else {
        await box.put('custom_title_$songId', customTitle);
      }
    } catch (e) {
      throw Exception('Failed to set custom title: $e');
    }
  }

  /// Apply custom title to a song
  Song applyCustomTitle(Song song) {
    final customTitle = getCustomTitle(song.id);
    if (customTitle != null && customTitle.isNotEmpty) {
      return song.copyWith(customTitle: customTitle);
    }
    return song;
  }

  /// Apply custom titles to a list of songs
  List<Song> applyCustomTitles(List<Song> songs) {
    return songs.map((song) => applyCustomTitle(song)).toList();
  }

  /// Clear custom title for a song
  Future<void> clearCustomTitle(String songId) async {
    await setCustomTitle(songId, null);
  }

  /// Check if a song has a custom title
  bool hasCustomTitle(String songId) {
    final customTitle = getCustomTitle(songId);
    return customTitle != null && customTitle.isNotEmpty;
  }
}
