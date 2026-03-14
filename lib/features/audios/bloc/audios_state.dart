import 'package:equatable/equatable.dart';
import 'package:play_beats/data/models/song_model.dart';

abstract class AudiosState extends Equatable {
  const AudiosState();

  @override
  List<Object?> get props => [];
}

class AudiosInitial extends AudiosState {}

class AudiosLoading extends AudiosState {}

class AudiosLoaded extends AudiosState {
  final List<Song> allSongs;
  final List<Song> displayedSongs;
  final String searchQuery;

  const AudiosLoaded({
    required this.allSongs,
    required this.displayedSongs,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [allSongs, displayedSongs, searchQuery];
}

class AudiosPermissionDenied extends AudiosState {}

class AudiosError extends AudiosState {
  final String message;
  const AudiosError(this.message);

  @override
  List<Object?> get props => [message];
}
