import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import 'package:play_beats/data/services/audio_player_service.dart';
import 'package:play_beats/features/player/bloc/player_event.dart';
import 'package:play_beats/features/player/bloc/player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioPlayerService _audioService;
  StreamSubscription? _playerStateSubscription;
  final _random = Random();

  PlayerBloc({required AudioPlayerService audioService})
      : _audioService = audioService,
        super(const PlayerStopped()) {
    on<PlaySong>(_onPlaySong);
    on<PauseSong>(_onPauseSong);
    on<ResumeSong>(_onResumeSong);
    on<StopSong>(_onStopSong);
    on<SeekSong>(_onSeekSong);
    on<NextSong>(_onNextSong);
    on<PreviousSong>(_onPreviousSong);
    on<ToggleShuffle>(_onToggleShuffle);
    on<SongCompleted>(_onSongCompleted);

    _listenToPlayerState();
  }

  void _listenToPlayerState() {
    _playerStateSubscription =
        _audioService.player.playerStateStream.listen((playerState) {
      final song = _audioService.currentSong;
      if (song == null) return;

      final currentState = state;
      final playlist = currentState.playlist;
      final index = currentState.currentIndex;
      final shuffle = currentState.shuffleEnabled;

      if (playerState.processingState == ProcessingState.completed) {
        add(SongCompleted());
        return;
      }

      if (playerState.processingState == ProcessingState.buffering ||
          playerState.processingState == ProcessingState.loading) {
        // ignore: invalid_use_of_visible_for_testing_member
        emit(PlayerBuffering(
          currentSong: song,
          playlist: playlist,
          currentIndex: index,
          shuffleEnabled: shuffle,
        ));
      } else if (playerState.playing) {
        // ignore: invalid_use_of_visible_for_testing_member
        emit(PlayerPlaying(
          currentSong: song,
          playlist: playlist,
          currentIndex: index,
          shuffleEnabled: shuffle,
        ));
      } else if (!playerState.playing &&
          playerState.processingState == ProcessingState.ready) {
        // ignore: invalid_use_of_visible_for_testing_member
        emit(PlayerPaused(
          currentSong: song,
          playlist: playlist,
          currentIndex: index,
          shuffleEnabled: shuffle,
        ));
      }
    });
  }

  Future<void> _onPlaySong(PlaySong event, Emitter<PlayerState> emit) async {
    final playlist =
        event.playlist.isNotEmpty ? event.playlist : [event.song];
    final index = playlist.indexOf(event.song);

    emit(PlayerBuffering(
      currentSong: event.song,
      playlist: playlist,
      currentIndex: index >= 0 ? index : 0,
      shuffleEnabled: state.shuffleEnabled,
    ));

    await _audioService.playSong(event.song);
  }

  Future<void> _onPauseSong(
      PauseSong event, Emitter<PlayerState> emit) async {
    await _audioService.pause();
  }

  Future<void> _onResumeSong(
      ResumeSong event, Emitter<PlayerState> emit) async {
    await _audioService.play();
  }

  Future<void> _onStopSong(StopSong event, Emitter<PlayerState> emit) async {
    await _audioService.stop();
    emit(PlayerStopped(shuffleEnabled: state.shuffleEnabled));
  }

  Future<void> _onSeekSong(SeekSong event, Emitter<PlayerState> emit) async {
    await _audioService.seek(event.position);
  }

  Future<void> _onNextSong(NextSong event, Emitter<PlayerState> emit) async {
    final playlist = state.playlist;
    if (playlist.isEmpty) return;

    final nextIndex = state.shuffleEnabled
        ? _randomIndex(playlist.length, state.currentIndex)
        : (state.currentIndex + 1) % playlist.length;
    add(PlaySong(song: playlist[nextIndex], playlist: playlist));
  }

  Future<void> _onPreviousSong(
      PreviousSong event, Emitter<PlayerState> emit) async {
    final playlist = state.playlist;
    if (playlist.isEmpty) return;

    final prevIndex = state.shuffleEnabled
        ? _randomIndex(playlist.length, state.currentIndex)
        : (state.currentIndex - 1 + playlist.length) % playlist.length;
    add(PlaySong(song: playlist[prevIndex], playlist: playlist));
  }

  void _onToggleShuffle(ToggleShuffle event, Emitter<PlayerState> emit) {
    final newShuffle = !state.shuffleEnabled;
    final song = state.currentSong;

    if (song == null || state is PlayerStopped) {
      emit(PlayerStopped(shuffleEnabled: newShuffle));
      return;
    }

    if (state is PlayerPlaying) {
      emit(PlayerPlaying(
        currentSong: song,
        playlist: state.playlist,
        currentIndex: state.currentIndex,
        shuffleEnabled: newShuffle,
      ));
    } else if (state is PlayerPaused) {
      emit(PlayerPaused(
        currentSong: song,
        playlist: state.playlist,
        currentIndex: state.currentIndex,
        shuffleEnabled: newShuffle,
      ));
    } else if (state is PlayerBuffering) {
      emit(PlayerBuffering(
        currentSong: song,
        playlist: state.playlist,
        currentIndex: state.currentIndex,
        shuffleEnabled: newShuffle,
      ));
    }
  }

  Future<void> _onSongCompleted(
      SongCompleted event, Emitter<PlayerState> emit) async {
    final playlist = state.playlist;
    if (playlist.isEmpty || playlist.length == 1) {
      await _audioService.stop();
      emit(PlayerStopped(shuffleEnabled: state.shuffleEnabled));
      return;
    }

    // Auto-advance to next song
    add(NextSong());
  }

  int _randomIndex(int length, int exclude) {
    if (length <= 1) return 0;
    int next;
    do {
      next = _random.nextInt(length);
    } while (next == exclude);
    return next;
  }

  @override
  Future<void> close() {
    _playerStateSubscription?.cancel();
    return super.close();
  }
}
