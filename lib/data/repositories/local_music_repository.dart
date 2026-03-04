import 'package:on_audio_query/on_audio_query.dart';
import 'package:play_beats/data/services/local_music_service.dart';

class LocalMusicRepository {
  final LocalMusicService _service = LocalMusicService();

  Future<bool> requestPermission() => _service.requestPermission();

  Future<List<SongModel>> getAllSongs() => _service.getAllSongs();

  Future<List<ArtistModel>> getAllArtists() => _service.getAllArtists();

  Future<List<AlbumModel>> getAllAlbums() => _service.getAllAlbums();

  Future<List<SongModel>> getSongsByArtist(int artistId) =>
      _service.getSongsByArtist(artistId);

  Future<List<SongModel>> getSongsByAlbum(int albumId) =>
      _service.getSongsByAlbum(albumId);
}
