import 'package:play_beats/data/models/song_model.dart';
import 'package:play_beats/data/services/hive_service.dart';

class FavoritesRepository {
  // In-memory cache for faster access
  List<Song>? _cachedFavorites;
  Set<String>? _favoriteIds;

  Future<List<Song>> getFavorites() async {
    if (_cachedFavorites != null) {
      return _cachedFavorites!;
    }
    
    final box = await HiveService.favoritesBox;
    _cachedFavorites = box.values.toList();
    _favoriteIds = {for (final song in _cachedFavorites!) song.id};
    return _cachedFavorites!;
  }

  Future<void> addFavorite(Song song) async {
    final box = await HiveService.favoritesBox;
    await box.put(song.id, song);
    _invalidateCache();
  }

  Future<void> removeFavorite(String songId) async {
    final box = await HiveService.favoritesBox;
    await box.delete(songId);
    _invalidateCache();
  }

  Future<void> addAllFavorites(List<Song> songs) async {
    final box = await HiveService.favoritesBox;
    await box.putAll({for (final song in songs) song.id: song});
    _invalidateCache();
  }

  Future<bool> isFavorite(String songId) async {
    // Check in-memory cache first (instant)
    if (_favoriteIds != null) {
      return _favoriteIds!.contains(songId);
    }
    
    final box = await HiveService.favoritesBox;
    return box.containsKey(songId);
  }

  void _invalidateCache() {
    _cachedFavorites = null;
    _favoriteIds = null;
  }

  /// Clear cache (for manual refresh)
  void clearCache() {
    _invalidateCache();
  }
}
