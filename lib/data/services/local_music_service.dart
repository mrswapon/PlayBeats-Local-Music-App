import 'dart:io';

import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalMusicService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Request the appropriate permission for the platform/SDK version.
  /// Returns true if granted.
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ uses READ_MEDIA_AUDIO, older uses READ_EXTERNAL_STORAGE
      final permission = await _audioQuery.permissionsStatus();
      if (permission) return true;

      // Try the on_audio_query built-in request first
      final granted = await _audioQuery.permissionsRequest();
      if (granted) return true;

      // Fallback to permission_handler
      final status = await Permission.audio.request();
      if (status.isGranted) return true;

      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    return true;
  }

  /// Get all songs on the device, filtering out short clips (< 30s).
  Future<List<SongModel>> getAllSongs() async {
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    // Filter out ringtones/notifications (< 30 seconds)
    return songs
        .where((s) => (s.duration ?? 0) > 30000)
        .toList();
  }

  /// Get all artists on the device.
  Future<List<ArtistModel>> getAllArtists() async {
    return await _audioQuery.queryArtists(
      sortType: ArtistSortType.ARTIST,
      orderType: OrderType.ASC_OR_SMALLER,
    );
  }

  /// Get all albums on the device.
  Future<List<AlbumModel>> getAllAlbums() async {
    return await _audioQuery.queryAlbums(
      sortType: AlbumSortType.ALBUM,
      orderType: OrderType.ASC_OR_SMALLER,
    );
  }

  /// Get songs for a specific artist.
  Future<List<SongModel>> getSongsByArtist(int artistId) async {
    final songs = await _audioQuery.queryAudiosFrom(
      AudiosFromType.ARTIST_ID,
      artistId,
    );
    return songs.where((s) => (s.duration ?? 0) > 30000).toList();
  }

  /// Get songs for a specific album.
  Future<List<SongModel>> getSongsByAlbum(int albumId) async {
    final songs = await _audioQuery.queryAudiosFrom(
      AudiosFromType.ALBUM_ID,
      albumId,
    );
    return songs.where((s) => (s.duration ?? 0) > 30000).toList();
  }
}
