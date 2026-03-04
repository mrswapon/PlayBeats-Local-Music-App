import 'package:play_beats/data/models/song_model.dart';
import 'package:play_beats/data/services/hive_service.dart';

class FavoritesRepository {
  List<Song> getFavorites() {
    return HiveService.favoritesBox.values.toList();
  }

  Future<void> addFavorite(Song song) async {
    await HiveService.favoritesBox.put(song.id, song);
  }

  Future<void> removeFavorite(String songId) async {
    await HiveService.favoritesBox.delete(songId);
  }

  bool isFavorite(String songId) {
    return HiveService.favoritesBox.containsKey(songId);
  }
}
