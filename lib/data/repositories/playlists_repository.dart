import 'package:play_beats/data/models/playlist_model.dart';
import 'package:play_beats/data/services/hive_service.dart';

class PlaylistsRepository {
  List<Playlist> getAllPlaylists() {
    return HiveService.playlistsBox.values.toList();
  }

  Playlist? getPlaylist(String id) {
    return HiveService.playlistsBox.get(id);
  }

  Future<void> createPlaylist(String name) async {
    final playlist = Playlist.create(name);
    await HiveService.playlistsBox.put(playlist.id, playlist);
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    await HiveService.playlistsBox.put(playlist.id, playlist);
  }

  Future<void> deletePlaylist(String id) async {
    await HiveService.playlistsBox.delete(id);
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final playlist = HiveService.playlistsBox.get(playlistId);
    if (playlist == null) return;

    // Don't add duplicates
    if (playlist.songIds.contains(songId)) return;

    final updated = playlist.copyWith(
      songIds: [...playlist.songIds, songId],
    );
    await HiveService.playlistsBox.put(playlistId, updated);
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final playlist = HiveService.playlistsBox.get(playlistId);
    if (playlist == null) return;

    final updated = playlist.copyWith(
      songIds: playlist.songIds.where((id) => id != songId).toList(),
    );
    await HiveService.playlistsBox.put(playlistId, updated);
  }

  Future<void> reorderSongInPlaylist(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    final playlist = HiveService.playlistsBox.get(playlistId);
    if (playlist == null) return;

    final songIds = List<String>.from(playlist.songIds);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final song = songIds.removeAt(oldIndex);
    songIds.insert(newIndex, song);

    final updated = playlist.copyWith(songIds: songIds);
    await HiveService.playlistsBox.put(playlistId, updated);
  }

  bool isSongInPlaylist(String playlistId, String songId) {
    final playlist = HiveService.playlistsBox.get(playlistId);
    return playlist?.songIds.contains(songId) ?? false;
  }
}
