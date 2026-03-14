import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/data/models/song_model.dart';
import 'package:play_beats/data/repositories/local_music_repository.dart';
import 'package:play_beats/features/audios/bloc/audios_event.dart';
import 'package:play_beats/features/audios/bloc/audios_state.dart';

class AudiosBloc extends Bloc<AudiosEvent, AudiosState> {
  final LocalMusicRepository repository;

  AudiosBloc({required this.repository}) : super(AudiosInitial()) {
    on<LoadAllAudios>(_onLoadAllAudios);
    on<RefreshAudios>(_onRefreshAudios);
    on<SearchAudios>(_onSearchAudios);
    on<ClearSearch>(_onClearSearch);
  }

  Future<void> _onLoadAllAudios(
    LoadAllAudios event,
    Emitter<AudiosState> emit,
  ) async {
    emit(AudiosLoading());

    final granted = await repository.requestPermission();
    if (!granted) {
      emit(AudiosPermissionDenied());
      return;
    }

    try {
      final deviceSongs = await repository.getAllSongs();
      final songs = deviceSongs.map((s) => Song.fromDeviceSong(s)).toList();
      emit(AudiosLoaded(allSongs: songs, displayedSongs: songs));
    } catch (e) {
      emit(AudiosError(e.toString()));
    }
  }

  Future<void> _onRefreshAudios(
    RefreshAudios event,
    Emitter<AudiosState> emit,
  ) async {
    try {
      final deviceSongs = await repository.getAllSongs();
      final songs = deviceSongs.map((s) => Song.fromDeviceSong(s)).toList();
      emit(AudiosLoaded(allSongs: songs, displayedSongs: songs));
    } catch (e) {
      emit(AudiosError(e.toString()));
    }
  }

  void _onSearchAudios(
    SearchAudios event,
    Emitter<AudiosState> emit,
  ) {
    final currentState = state;
    if (currentState is AudiosLoaded) {
      final query = event.query.toLowerCase();
      final filtered = currentState.allSongs.where((song) {
        return song.title.toLowerCase().contains(query) ||
            song.artist.toLowerCase().contains(query) ||
            song.album.toLowerCase().contains(query);
      }).toList();
      emit(AudiosLoaded(
        allSongs: currentState.allSongs,
        displayedSongs: filtered,
        searchQuery: event.query,
      ));
    }
  }

  void _onClearSearch(
    ClearSearch event,
    Emitter<AudiosState> emit,
  ) {
    final currentState = state;
    if (currentState is AudiosLoaded) {
      emit(AudiosLoaded(
        allSongs: currentState.allSongs,
        displayedSongs: currentState.allSongs,
      ));
    }
  }
}
