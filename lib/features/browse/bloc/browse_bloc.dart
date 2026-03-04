import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/data/models/song_model.dart';
import 'package:play_beats/data/repositories/local_music_repository.dart';
import 'package:play_beats/features/browse/bloc/browse_event.dart';
import 'package:play_beats/features/browse/bloc/browse_state.dart';

class BrowseBloc extends Bloc<BrowseEvent, BrowseState> {
  final LocalMusicRepository repository;

  BrowseBloc({required this.repository}) : super(BrowseInitial()) {
    on<LoadArtists>(_onLoadArtists);
    on<LoadAlbums>(_onLoadAlbums);
    on<LoadArtistSongs>(_onLoadArtistSongs);
    on<LoadAlbumSongs>(_onLoadAlbumSongs);
    on<BackToBrowse>(_onBackToBrowse);
  }

  // Track the last browse mode to restore on back
  bool _lastWasArtists = true;

  Future<void> _onLoadArtists(
    LoadArtists event,
    Emitter<BrowseState> emit,
  ) async {
    emit(BrowseLoading());
    _lastWasArtists = true;
    try {
      final artists = await repository.getAllArtists();
      emit(BrowseArtistsLoaded(artists));
    } catch (e) {
      emit(BrowseError(e.toString()));
    }
  }

  Future<void> _onLoadAlbums(
    LoadAlbums event,
    Emitter<BrowseState> emit,
  ) async {
    emit(BrowseLoading());
    _lastWasArtists = false;
    try {
      final albums = await repository.getAllAlbums();
      emit(BrowseAlbumsLoaded(albums));
    } catch (e) {
      emit(BrowseError(e.toString()));
    }
  }

  Future<void> _onLoadArtistSongs(
    LoadArtistSongs event,
    Emitter<BrowseState> emit,
  ) async {
    emit(BrowseLoading());
    try {
      final deviceSongs = await repository.getSongsByArtist(event.artistId);
      final songs = deviceSongs.map((s) => Song.fromDeviceSong(s)).toList();
      emit(BrowseSongsLoaded(songs: songs, title: event.artistName));
    } catch (e) {
      emit(BrowseError(e.toString()));
    }
  }

  Future<void> _onLoadAlbumSongs(
    LoadAlbumSongs event,
    Emitter<BrowseState> emit,
  ) async {
    emit(BrowseLoading());
    try {
      final deviceSongs = await repository.getSongsByAlbum(event.albumId);
      final songs = deviceSongs.map((s) => Song.fromDeviceSong(s)).toList();
      emit(BrowseSongsLoaded(songs: songs, title: event.albumName));
    } catch (e) {
      emit(BrowseError(e.toString()));
    }
  }

  Future<void> _onBackToBrowse(
    BackToBrowse event,
    Emitter<BrowseState> emit,
  ) async {
    if (_lastWasArtists) {
      add(LoadArtists());
    } else {
      add(LoadAlbums());
    }
  }
}
