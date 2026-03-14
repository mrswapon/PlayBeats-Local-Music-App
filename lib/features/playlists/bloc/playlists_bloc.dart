import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/data/repositories/playlists_repository.dart';
import 'package:play_beats/features/playlists/bloc/playlists_event.dart';
import 'package:play_beats/features/playlists/bloc/playlists_state.dart';

class PlaylistsBloc extends Bloc<PlaylistsEvent, PlaylistsState> {
  final PlaylistsRepository repository;

  PlaylistsBloc({required this.repository}) : super(PlaylistsInitial()) {
    on<LoadPlaylists>(_onLoadPlaylists);
    on<CreatePlaylist>(_onCreatePlaylist);
    on<DeletePlaylist>(_onDeletePlaylist);
    on<RenamePlaylist>(_onRenamePlaylist);
    on<AddSongToPlaylist>(_onAddSongToPlaylist);
    on<RemoveSongFromPlaylist>(_onRemoveSongFromPlaylist);
    on<ReorderSongInPlaylist>(_onReorderSongInPlaylist);
  }

  Future<void> _onLoadPlaylists(
    LoadPlaylists event,
    Emitter<PlaylistsState> emit,
  ) async {
    emit(PlaylistsLoading());
    try {
      final playlists = await repository.getAllPlaylists();
      emit(PlaylistsLoaded(playlists));
    } catch (e) {
      emit(PlaylistsError(e.toString()));
    }
  }

  Future<void> _onCreatePlaylist(
    CreatePlaylist event,
    Emitter<PlaylistsState> emit,
  ) async {
    try {
      await repository.createPlaylist(event.name);
      final playlists = await repository.getAllPlaylists();
      emit(PlaylistsLoaded(playlists));
    } catch (e) {
      emit(PlaylistsError(e.toString()));
    }
  }

  Future<void> _onDeletePlaylist(
    DeletePlaylist event,
    Emitter<PlaylistsState> emit,
  ) async {
    try {
      await repository.deletePlaylist(event.playlistId);
      final playlists = await repository.getAllPlaylists();
      emit(PlaylistsLoaded(playlists));
    } catch (e) {
      emit(PlaylistsError(e.toString()));
    }
  }

  Future<void> _onRenamePlaylist(
    RenamePlaylist event,
    Emitter<PlaylistsState> emit,
  ) async {
    try {
      final playlist = await repository.getPlaylist(event.playlistId);
      if (playlist == null) return;

      final updated = playlist.copyWith(name: event.newName);
      await repository.updatePlaylist(updated);
      final playlists = await repository.getAllPlaylists();
      emit(PlaylistsLoaded(playlists));
    } catch (e) {
      emit(PlaylistsError(e.toString()));
    }
  }

  Future<void> _onAddSongToPlaylist(
    AddSongToPlaylist event,
    Emitter<PlaylistsState> emit,
  ) async {
    try {
      await repository.addSongToPlaylist(event.playlistId, event.songId);
      final playlists = await repository.getAllPlaylists();
      emit(PlaylistsLoaded(playlists));
    } catch (e) {
      emit(PlaylistsError(e.toString()));
    }
  }

  Future<void> _onRemoveSongFromPlaylist(
    RemoveSongFromPlaylist event,
    Emitter<PlaylistsState> emit,
  ) async {
    try {
      await repository.removeSongFromPlaylist(event.playlistId, event.songId);
      final playlists = await repository.getAllPlaylists();
      emit(PlaylistsLoaded(playlists));
    } catch (e) {
      emit(PlaylistsError(e.toString()));
    }
  }

  Future<void> _onReorderSongInPlaylist(
    ReorderSongInPlaylist event,
    Emitter<PlaylistsState> emit,
  ) async {
    try {
      await repository.reorderSongInPlaylist(
        event.playlistId,
        event.oldIndex,
        event.newIndex,
      );
      final playlists = await repository.getAllPlaylists();
      emit(PlaylistsLoaded(playlists));
    } catch (e) {
      emit(PlaylistsError(e.toString()));
    }
  }
}
