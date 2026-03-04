import 'package:equatable/equatable.dart';
import 'package:play_beats/data/models/song_model.dart';

abstract class SongsState extends Equatable {
  const SongsState();

  @override
  List<Object?> get props => [];
}

class SongsInitial extends SongsState {}

class SongsLoading extends SongsState {}

class SongsLoaded extends SongsState {
  final List<Song> allSongs;
  final List<Song> displayedSongs;
  final String searchQuery;

  const SongsLoaded({
    required this.allSongs,
    required this.displayedSongs,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [allSongs, displayedSongs, searchQuery];
}

class SongsPermissionDenied extends SongsState {}

class SongsError extends SongsState {
  final String message;
  const SongsError(this.message);

  @override
  List<Object?> get props => [message];
}
