import 'package:play_beats/data/models/playlist_model.dart';
import 'package:play_beats/data/services/hive_service.dart';

class PlaylistsRepository {
  // In-memory cache
  List<Playlist>? _cachedPlaylists;
  Map<String, Playlist>? _playlistMap;

  Future<List<Playlist>> getAllPlaylists() async {
    if (_cachedPlaylists != null) {
      return _cachedPlaylists!;
    }
    
    final box = await HiveService.playlistsBox;
    _cachedPlaylists = box.values.toList();
    _playlistMap = {for (final p in _cachedPlaylists!) p.id: p};
    return _cachedPlaylists!;
  }

  Future<Playlist?> getPlaylist(String id) async {
    // Check cache first
    if (_playlistMap != null) {
      return _playlistMap![id];
    }
    
    final box = await HiveService.playlistsBox;
    return box.get(id);
  }

  Future<void> createPlaylist(String name) async {
    final playlist = Playlist.create(name);
    final box = await HiveService.playlistsBox;
    await box.put(playlist.id, playlist);
    _invalidateCache();
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    final box = await HiveService.playlistsBox;
    await box.put(playlist.id, playlist);
    _invalidateCache();
  }

  Future<void> deletePlaylist(String id) async {
    final box = await HiveService.playlistsBox;
    await box.delete(id);
    _invalidateCache();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final box = await HiveService.playlistsBox;
    final playlist = box.get(playlistId);
    if (playlist == null) return;

    if (playlist.songIds.contains(songId)) return;

    final updated = playlist.copyWith(
      songIds: [...playlist.songIds, songId],
    );
    await box.put(playlistId, updated);
    _invalidateCache();
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final box = await HiveService.playlistsBox;
    final playlist = box.get(playlistId);
    if (playlist == null) return;

    final updated = playlist.copyWith(
      songIds: playlist.songIds.where((id) => id != songId).toList(),
    );
    await box.put(playlistId, updated);
    _invalidateCache();
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
    _invalidateCache();
  }

  Future<bool> isSongInPlaylist(String playlistId, String songId) async {
    final playlist = await getPlaylist(playlistId);
    return playlist?.songIds.contains(songId) ?? false;
  }

  void _invalidateCache() {
    _cachedPlaylists = null;
    _playlistMap = null;
  }

  void clearCache() {
    _invalidateCache();
  }
}
