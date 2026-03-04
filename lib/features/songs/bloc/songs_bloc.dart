import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/data/models/song_model.dart';
import 'package:play_beats/data/repositories/local_music_repository.dart';
import 'package:play_beats/features/songs/bloc/songs_event.dart';
import 'package:play_beats/features/songs/bloc/songs_state.dart';

class SongsBloc extends Bloc<SongsEvent, SongsState> {
  final LocalMusicRepository repository;

  SongsBloc({required this.repository}) : super(SongsInitial()) {
    on<LoadAllSongs>(_onLoadAllSongs);
    on<RefreshSongs>(_onRefreshSongs);
    on<SearchSongs>(_onSearchSongs);
    on<ClearSearch>(_onClearSearch);
  }

  Future<void> _onLoadAllSongs(
    LoadAllSongs event,
    Emitter<SongsState> emit,
  ) async {
    emit(SongsLoading());

    final granted = await repository.requestPermission();
    if (!granted) {
      emit(SongsPermissionDenied());
      return;
    }

    try {
      final deviceSongs = await repository.getAllSongs();
      final songs = deviceSongs.map((s) => Song.fromDeviceSong(s)).toList();
      emit(SongsLoaded(allSongs: songs, displayedSongs: songs));
    } catch (e) {
      emit(SongsError(e.toString()));
    }
  }

  Future<void> _onRefreshSongs(
    RefreshSongs event,
    Emitter<SongsState> emit,
  ) async {
    try {
      final deviceSongs = await repository.getAllSongs();
      final songs = deviceSongs.map((s) => Song.fromDeviceSong(s)).toList();
      emit(SongsLoaded(allSongs: songs, displayedSongs: songs));
    } catch (e) {
      emit(SongsError(e.toString()));
    }
  }

  void _onSearchSongs(
    SearchSongs event,
    Emitter<SongsState> emit,
  ) {
    final currentState = state;
    if (currentState is SongsLoaded) {
      final query = event.query.toLowerCase();
      final filtered = currentState.allSongs.where((song) {
        return song.title.toLowerCase().contains(query) ||
            song.artist.toLowerCase().contains(query) ||
            song.album.toLowerCase().contains(query);
      }).toList();
      emit(SongsLoaded(
        allSongs: currentState.allSongs,
        displayedSongs: filtered,
        searchQuery: event.query,
      ));
    }
  }

  void _onClearSearch(
    ClearSearch event,
    Emitter<SongsState> emit,
  ) {
    final currentState = state;
    if (currentState is SongsLoaded) {
      emit(SongsLoaded(
        allSongs: currentState.allSongs,
        displayedSongs: currentState.allSongs,
      ));
    }
  }
}
