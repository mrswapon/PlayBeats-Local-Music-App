import 'dart:async';
import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import 'package:play_beats/data/models/video_model.dart';
import 'package:play_beats/data/services/audio_player_service.dart';

abstract class VideoAsAudioState extends Equatable {
  const VideoAsAudioState();
  
  Video? get currentVideo;
  List<Video> get playlist;
  int get currentIndex;
  bool get shuffleEnabled;
}

class VideoAsAudioStopped extends VideoAsAudioState {
  @override
  final bool shuffleEnabled;
  
  const VideoAsAudioStopped({this.shuffleEnabled = false});
  
  @override
  Video? get currentVideo => null;
  @override
  List<Video> get playlist => [];
  @override
  int get currentIndex => 0;
  
  @override
  List<Object?> get props => [shuffleEnabled];
}

class VideoAsAudioPlaying extends VideoAsAudioState {
  @override
  final Video currentVideo;
  @override
  final List<Video> playlist;
  @override
  final int currentIndex;
  @override
  final bool shuffleEnabled;

  const VideoAsAudioPlaying({
    required this.currentVideo,
    required this.playlist,
    required this.currentIndex,
    this.shuffleEnabled = false,
  });

  @override
  List<Object?> get props => [currentVideo, playlist, currentIndex, shuffleEnabled];
}

class VideoAsAudioPaused extends VideoAsAudioState {
  @override
  final Video currentVideo;
  @override
  final List<Video> playlist;
  @override
  final int currentIndex;
  @override
  final bool shuffleEnabled;

  const VideoAsAudioPaused({
    required this.currentVideo,
    required this.playlist,
    required this.currentIndex,
    this.shuffleEnabled = false,
  });

  @override
  List<Object?> get props => [currentVideo, playlist, currentIndex, shuffleEnabled];
}

class VideoAsAudioBuffering extends VideoAsAudioState {
  @override
  final Video currentVideo;
  @override
  final List<Video> playlist;
  @override
  final int currentIndex;
  @override
  final bool shuffleEnabled;

  const VideoAsAudioBuffering({
    required this.currentVideo,
    required this.playlist,
    required this.currentIndex,
    this.shuffleEnabled = false,
  });

  @override
  List<Object?> get props => [currentVideo, playlist, currentIndex, shuffleEnabled];
}

abstract class VideoAsAudioEvent extends Equatable {
  const VideoAsAudioEvent();
  
  @override
  List<Object?> get props => [];
}

class PlayVideoAsAudio extends VideoAsAudioEvent {
  final Video video;
  final List<Video> playlist;

  const PlayVideoAsAudio({required this.video, this.playlist = const []});

  @override
  List<Object?> get props => [video, playlist];
}

class PauseVideoAsAudio extends VideoAsAudioEvent {}

class ResumeVideoAsAudio extends VideoAsAudioEvent {}

class StopVideoAsAudio extends VideoAsAudioEvent {}

class SeekVideoAsAudio extends VideoAsAudioEvent {
  final Duration position;

  const SeekVideoAsAudio(this.position);

  @override
  List<Object?> get props => [position];
}

class NextVideoAsAudio extends VideoAsAudioEvent {}

class PreviousVideoAsAudio extends VideoAsAudioEvent {}

class ToggleShuffleVideoAsAudio extends VideoAsAudioEvent {}

class VideoAsAudioBloc extends Bloc<VideoAsAudioEvent, VideoAsAudioState> {
  final AudioPlayerService _service;
  StreamSubscription? _playerStateSubscription;
  final _random = Random();

  VideoAsAudioBloc({required AudioPlayerService service})
      : _service = service,
        super(const VideoAsAudioStopped()) {
    on<PlayVideoAsAudio>(_onPlay);
    on<PauseVideoAsAudio>(_onPause);
    on<ResumeVideoAsAudio>(_onResume);
    on<StopVideoAsAudio>(_onStop);
    on<SeekVideoAsAudio>(_onSeek);
    on<NextVideoAsAudio>(_onNext);
    on<PreviousVideoAsAudio>(_onPrevious);
    on<ToggleShuffleVideoAsAudio>(_onToggleShuffle);

    _listenToPlayerState();
  }

  void _listenToPlayerState() {
    _playerStateSubscription = _service.player.playerStateStream.listen((playerState) {
      final video = _service.currentVideo;
      if (video == null) return;

      final currentState = state;
      final playlist = currentState.playlist;
      final index = currentState.currentIndex;
      final shuffle = currentState.shuffleEnabled;

      if (playerState.processingState == ProcessingState.completed) {
        add(NextVideoAsAudio());
        return;
      }

      if (playerState.processingState == ProcessingState.buffering ||
          playerState.processingState == ProcessingState.loading) {
        emit(VideoAsAudioBuffering(
          currentVideo: video,
          playlist: playlist,
          currentIndex: index,
          shuffleEnabled: shuffle,
        ));
      } else if (playerState.playing) {
        emit(VideoAsAudioPlaying(
          currentVideo: video,
          playlist: playlist,
          currentIndex: index,
          shuffleEnabled: shuffle,
        ));
      } else if (!playerState.playing &&
          playerState.processingState == ProcessingState.ready) {
        emit(VideoAsAudioPaused(
          currentVideo: video,
          playlist: playlist,
          currentIndex: index,
          shuffleEnabled: shuffle,
        ));
      }
    });
  }

  Future<void> _onPlay(PlayVideoAsAudio event, Emitter<VideoAsAudioState> emit) async {
    final playlist = event.playlist.isNotEmpty ? event.playlist : [event.video];
    final index = playlist.indexOf(event.video);

    emit(VideoAsAudioBuffering(
      currentVideo: event.video,
      playlist: playlist,
      currentIndex: index >= 0 ? index : 0,
      shuffleEnabled: state.shuffleEnabled,
    ));

    _service.playVideoAsAudio(event.video, playlist: playlist, index: index);
  }

  Future<void> _onPause(PauseVideoAsAudio event, Emitter<VideoAsAudioState> emit) async {
    await _service.pause();
  }

  Future<void> _onResume(ResumeVideoAsAudio event, Emitter<VideoAsAudioState> emit) async {
    await _service.play();
  }

  Future<void> _onStop(StopVideoAsAudio event, Emitter<VideoAsAudioState> emit) async {
    await _service.stop();
    emit(VideoAsAudioStopped(shuffleEnabled: state.shuffleEnabled));
  }

  Future<void> _onSeek(SeekVideoAsAudio event, Emitter<VideoAsAudioState> emit) async {
    await _service.seek(event.position);
  }

  Future<void> _onNext(NextVideoAsAudio event, Emitter<VideoAsAudioState> emit) async {
    final playlist = state.playlist;
    if (playlist.isEmpty) return;

    final nextIndex = state.shuffleEnabled
        ? _randomIndex(playlist.length, state.currentIndex)
        : (state.currentIndex + 1) % playlist.length;
    add(PlayVideoAsAudio(video: playlist[nextIndex], playlist: playlist));
  }

  Future<void> _onPrevious(PreviousVideoAsAudio event, Emitter<VideoAsAudioState> emit) async {
    final playlist = state.playlist;
    if (playlist.isEmpty) return;

    final prevIndex = state.shuffleEnabled
        ? _randomIndex(playlist.length, state.currentIndex)
        : (state.currentIndex - 1 + playlist.length) % playlist.length;
    add(PlayVideoAsAudio(video: playlist[prevIndex], playlist: playlist));
  }

  void _onToggleShuffle(ToggleShuffleVideoAsAudio event, Emitter<VideoAsAudioState> emit) {
    final newShuffle = !state.shuffleEnabled;
    final video = state.currentVideo;

    if (video == null || state is VideoAsAudioStopped) {
      emit(VideoAsAudioStopped(shuffleEnabled: newShuffle));
      return;
    }

    if (state is VideoAsAudioPlaying) {
      final s = state as VideoAsAudioPlaying;
      emit(VideoAsAudioPlaying(
        currentVideo: video,
        playlist: s.playlist,
        currentIndex: s.currentIndex,
        shuffleEnabled: newShuffle,
      ));
    } else if (state is VideoAsAudioPaused) {
      final s = state as VideoAsAudioPaused;
      emit(VideoAsAudioPaused(
        currentVideo: video,
        playlist: s.playlist,
        currentIndex: s.currentIndex,
        shuffleEnabled: newShuffle,
      ));
    } else if (state is VideoAsAudioBuffering) {
      final s = state as VideoAsAudioBuffering;
      emit(VideoAsAudioBuffering(
        currentVideo: video,
        playlist: s.playlist,
        currentIndex: s.currentIndex,
        shuffleEnabled: newShuffle,
      ));
    }
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
