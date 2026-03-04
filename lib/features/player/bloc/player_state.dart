import 'package:equatable/equatable.dart';
import 'package:play_beats/data/models/song_model.dart';

abstract class PlayerState extends Equatable {
  final Song? currentSong;
  final List<Song> playlist;
  final int currentIndex;
  final bool shuffleEnabled;

  const PlayerState({
    this.currentSong,
    this.playlist = const [],
    this.currentIndex = 0,
    this.shuffleEnabled = false,
  });

  @override
  List<Object?> get props =>
      [currentSong, playlist, currentIndex, shuffleEnabled];
}

class PlayerStopped extends PlayerState {
  const PlayerStopped({super.shuffleEnabled});
}

class PlayerPlaying extends PlayerState {
  const PlayerPlaying({
    required super.currentSong,
    super.playlist,
    super.currentIndex,
    super.shuffleEnabled,
  });
}

class PlayerPaused extends PlayerState {
  const PlayerPaused({
    required super.currentSong,
    super.playlist,
    super.currentIndex,
    super.shuffleEnabled,
  });
}

class PlayerBuffering extends PlayerState {
  const PlayerBuffering({
    required super.currentSong,
    super.playlist,
    super.currentIndex,
    super.shuffleEnabled,
  });
}
