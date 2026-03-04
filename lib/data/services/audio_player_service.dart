import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:play_beats/data/models/song_model.dart';

class AudioPlayerService extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  final _currentSongController = StreamController<Song?>.broadcast();
  Song? _currentSong;
  StreamSubscription<PlaybackEvent>? _playbackSubscription;

  AudioPlayerService() {
    _playbackSubscription = _player.playbackEventStream.listen(_broadcastState);
  }

  AudioPlayer get player => _player;
  Stream<Song?> get currentSongStream => _currentSongController.stream;
  Song? get currentSong => _currentSong;

  Future<void> playSong(Song song) async {
    _currentSong = song;
    _currentSongController.add(song);

    mediaItem.add(MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: Duration(milliseconds: song.duration),
    ));

    try {
      await _player.setFilePath(song.filePath);
      await _player.play();
    } catch (e) {
      // ignore: avoid_print
      print('PlayBeats: Error playing song: $e');
    }
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  Future<void> dispose() async {
    await _playbackSubscription?.cancel();
    await _player.dispose();
    await _currentSongController.close();
  }
}

Future<AudioPlayerService> initAudioService() async {
  return await AudioService.init(
    builder: () => AudioPlayerService(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mr_swapon.play_beats.audio',
      androidNotificationChannelName: 'PlayBeats Audio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}
