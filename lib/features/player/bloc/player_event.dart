import 'package:equatable/equatable.dart';
import 'package:play_beats/data/models/song_model.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

class PlaySong extends PlayerEvent {
  final Song song;
  final List<Song> playlist;

  const PlaySong({required this.song, this.playlist = const []});

  @override
  List<Object?> get props => [song, playlist];
}

class PauseSong extends PlayerEvent {}

class ResumeSong extends PlayerEvent {}

class StopSong extends PlayerEvent {}

class SeekSong extends PlayerEvent {
  final Duration position;

  const SeekSong(this.position);

  @override
  List<Object?> get props => [position];
}

class NextSong extends PlayerEvent {}

class PreviousSong extends PlayerEvent {}

class ToggleShuffle extends PlayerEvent {}

class SongCompleted extends PlayerEvent {}
