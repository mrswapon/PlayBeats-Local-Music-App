import 'package:equatable/equatable.dart';
import 'package:play_beats/data/models/playlist_model.dart';
import 'package:play_beats/data/models/song_model.dart';

abstract class PlaylistsState extends Equatable {
  const PlaylistsState();

  @override
  List<Object?> get props => [];
}

class PlaylistsInitial extends PlaylistsState {}

class PlaylistsLoading extends PlaylistsState {}

class PlaylistsLoaded extends PlaylistsState {
  final List<Playlist> playlists;

  const PlaylistsLoaded(this.playlists);

  @override
  List<Object?> get props => [playlists];
}

class PlaylistsError extends PlaylistsState {
  final String message;

  const PlaylistsError(this.message);

  @override
  List<Object?> get props => [message];
}

class PlaylistDetailLoaded extends PlaylistsState {
  final Playlist playlist;
  final List<Song> songs;

  const PlaylistDetailLoaded({required this.playlist, required this.songs});

  @override
  List<Object?> get props => [playlist, songs];
}
