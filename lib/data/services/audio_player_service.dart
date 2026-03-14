import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:play_beats/data/models/song_model.dart';

class AudioPlayerService extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  final _currentSongController = StreamController<Song?>.broadcast();
  Song? _currentSong;
  StreamSubscription<PlaybackEvent>? _playbackSubscription;
  List<Song> _playlist = [];
  int _currentIndex = 0;

  AudioPlayerService() {
    _playbackSubscription = _player.playbackEventStream.listen(_broadcastState);
  }

  AudioPlayer get player => _player;
  Stream<Song?> get currentSongStream => _currentSongController.stream;
  Song? get currentSong => _currentSong;

  void setPlaylist(List<Song> playlist, int index) {
    _playlist = playlist;
    _currentIndex = index;
  }

  Future<void> playSong(Song song, {List<Song>? playlist, int? index}) async {
    _currentSong = song;
    _currentSongController.add(song);

    if (playlist != null && index != null) {
      _playlist = playlist;
      _currentIndex = index;
    }

    final artUri = song.albumId != 0 
        ? 'content://media/external/audio/albumart/${song.albumId}'
        : null;

    mediaItem.add(MediaItem(
      id: song.id,
      title: song.displayTitle,
      artist: song.artist,
      album: song.album,
      duration: Duration(milliseconds: song.duration),
      artUri: artUri != null ? Uri.parse(artUri) : null,
    ));

    try {
      await _player.setFilePath(song.filePath);
      await _player.play();
    } catch (e) {
      // Error playing song
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

  @override
  Future<void> skipToNext() async {
    if (_playlist.isEmpty) return;
    final nextIndex = (_currentIndex + 1) % _playlist.length;
    await playSong(_playlist[nextIndex], playlist: _playlist, index: nextIndex);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty) return;
    final prevIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await playSong(_playlist[prevIndex], playlist: _playlist, index: prevIndex);
  }

  void _broadcastState(PlaybackEvent event) {
    final isPlaying = _player.playing;
    final processingState = _player.processingState;

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (isPlaying) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.stop,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[processingState]!,
      playing: isPlaying,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
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
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidShowNotificationBadge: true,
      preloadArtwork: false,
      artDownscaleWidth: 300,
      artDownscaleHeight: 300,
      fastForwardInterval: Duration(seconds: 10),
      androidNotificationChannelDescription: 'Audio playback notification for PlayBeats',
    ),
  );
}
