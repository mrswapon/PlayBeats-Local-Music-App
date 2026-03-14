import 'package:play_beats/data/models/song_model.dart';
import 'package:play_beats/data/services/hive_service.dart';

class FavoritesRepository {
  Future<List<Song>> getFavorites() async {
    final box = await HiveService.favoritesBox;
    return box.values.toList();
  }

  Future<void> addFavorite(Song song) async {
    final box = await HiveService.favoritesBox;
    await box.put(song.id, song);
  }

  Future<void> removeFavorite(String songId) async {
    final box = await HiveService.favoritesBox;
    await box.delete(songId);
  }

  Future<bool> isFavorite(String songId) async {
    final box = await HiveService.favoritesBox;
    return box.containsKey(songId);
  }
}
