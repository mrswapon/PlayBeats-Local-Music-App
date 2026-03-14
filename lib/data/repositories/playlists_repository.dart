import 'package:play_beats/data/models/playlist_model.dart';
import 'package:play_beats/data/services/hive_service.dart';

class PlaylistsRepository {
  Future<List<Playlist>> getAllPlaylists() async {
    final box = await HiveService.playlistsBox;
    return box.values.toList();
  }

  Future<Playlist?> getPlaylist(String id) async {
    final box = await HiveService.playlistsBox;
    return box.get(id);
  }

  Future<void> createPlaylist(String name) async {
    final playlist = Playlist.create(name);
    final box = await HiveService.playlistsBox;
    await box.put(playlist.id, playlist);
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    final box = await HiveService.playlistsBox;
    await box.put(playlist.id, playlist);
  }

  Future<void> deletePlaylist(String id) async {
    final box = await HiveService.playlistsBox;
    await box.delete(id);
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final box = await HiveService.playlistsBox;
    final playlist = box.get(playlistId);
    if (playlist == null) return;

    // Don't add duplicates
    if (playlist.songIds.contains(songId)) return;

    final updated = playlist.copyWith(
      songIds: [...playlist.songIds, songId],
    );
    await box.put(playlistId, updated);
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final box = await HiveService.playlistsBox;
    final playlist = box.get(playlistId);
    if (playlist == null) return;

    final updated = playlist.copyWith(
      songIds: playlist.songIds.where((id) => id != songId).toList(),
    );
    await box.put(playlistId, updated);
  }

  Future<void> reorderSongInPlaylist(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    final box = await HiveService.playlistsBox;
    final playlist = box.get(playlistId);
    if (playlist == null) return;

    final songIds = List<String>.from(playlist.songIds);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final song = songIds.removeAt(oldIndex);
    songIds.insert(newIndex, song);

    final updated = playlist.copyWith(songIds: songIds);
    await box.put(playlistId, updated);
  }

  Future<bool> isSongInPlaylist(String playlistId, String songId) async {
    final box = await HiveService.playlistsBox;
    final playlist = box.get(playlistId);
    return playlist?.songIds.contains(songId) ?? false;
  }
}
