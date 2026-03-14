import 'package:play_beats/data/models/song_model.dart';
import 'package:play_beats/data/services/hive_service.dart';

/// Repository for managing song metadata overrides (custom titles, etc.)
/// Stores user customizations in Hive separately from the original file metadata.
class SongMetadataRepository {

  /// Get custom title for a song
  Future<String?> getCustomTitle(String songId) async {
    try {
      final box = await HiveService.settingsBox;
      return box.get('custom_title_$songId');
    } catch (e) {
      return null;
    }
  }

  /// Set custom title for a song
  Future<void> setCustomTitle(String songId, String? customTitle) async {
    try {
      final box = await HiveService.settingsBox;
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
  Future<Song> applyCustomTitle(Song song) async {
    final customTitle = await getCustomTitle(song.id);
    if (customTitle != null && customTitle.isNotEmpty) {
      return song.copyWith(customTitle: customTitle);
    }
    return song;
  }

  /// Apply custom titles to a list of songs
  Future<List<Song>> applyCustomTitles(List<Song> songs) async {
    final updated = <Song>[];
    for (final song in songs) {
      updated.add(await applyCustomTitle(song));
    }
    return updated;
  }

  /// Clear custom title for a song
  Future<void> clearCustomTitle(String songId) async {
    await setCustomTitle(songId, null);
  }

  /// Check if a song has a custom title
  Future<bool> hasCustomTitle(String songId) async {
    final customTitle = await getCustomTitle(songId);
    return customTitle != null && customTitle.isNotEmpty;
  }
}
