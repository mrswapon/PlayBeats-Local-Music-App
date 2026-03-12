import 'package:equatable/equatable.dart';

abstract class PlaylistsEvent extends Equatable {
  const PlaylistsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPlaylists extends PlaylistsEvent {}

class CreatePlaylist extends PlaylistsEvent {
  final String name;

  const CreatePlaylist(this.name);

  @override
  List<Object?> get props => [name];
}

class DeletePlaylist extends PlaylistsEvent {
  final String playlistId;

  const DeletePlaylist(this.playlistId);

  @override
  List<Object?> get props => [playlistId];
}

class RenamePlaylist extends PlaylistsEvent {
  final String playlistId;
  final String newName;

  const RenamePlaylist({required this.playlistId, required this.newName});

  @override
  List<Object?> get props => [playlistId, newName];
}

class AddSongToPlaylist extends PlaylistsEvent {
  final String playlistId;
  final String songId;

  const AddSongToPlaylist({required this.playlistId, required this.songId});

  @override
  List<Object?> get props => [playlistId, songId];
}

class RemoveSongFromPlaylist extends PlaylistsEvent {
  final String playlistId;
  final String songId;

  const RemoveSongFromPlaylist({required this.playlistId, required this.songId});

  @override
  List<Object?> get props => [playlistId, songId];
}

class ReorderSongInPlaylist extends PlaylistsEvent {
  final String playlistId;
  final int oldIndex;
  final int newIndex;

  const ReorderSongInPlaylist({
    required this.playlistId,
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  List<Object?> get props => [playlistId, oldIndex, newIndex];
}
