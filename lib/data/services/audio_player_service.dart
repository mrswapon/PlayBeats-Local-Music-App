import 'dart:async';
import 'dart:developer';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:play_beats/data/models/song_model.dart';
import 'package:play_beats/data/models/video_model.dart';

/// Combined audio player service for both songs and video-as-audio
class AudioPlayerService extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  final _currentSongController = StreamController<Song?>.broadcast();
  final _currentVideoController = StreamController<Video?>.broadcast();
  
  Song? _currentSong;
  Video? _currentVideo;
  bool _isVideoMode = false;
  
  StreamSubscription<PlaybackEvent>? _playbackSubscription;
  List<dynamic> _playlist = []; // Can hold Song or Video
  int _currentIndex = 0;
  
  // Preload cache for faster playback
  dynamic _nextItem;

  AudioPlayerService() {
    _playbackSubscription = _player.playbackEventStream.listen(_broadcastState);
    
    // Listen for completion and auto-play next
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  AudioPlayer get player => _player;
  Stream<Song?> get currentSongStream => _currentSongController.stream;
  Stream<Video?> get currentVideoStream => _currentVideoController.stream;
  Song? get currentSong => _currentSong;
  Video? get currentVideo => _currentVideo;
  bool get isVideoMode => _isVideoMode;

  /// Play a song
  Future<void> playSong(Song song, {List<Song>? playlist, int? index}) async {
    _isVideoMode = false;
    _currentSong = song;
    _currentVideo = null;
    _currentSongController.add(song);
    _currentVideoController.add(null);

    if (playlist != null && index != null) {
      _playlist = playlist;
      _currentIndex = index;
      _preloadNextItem(index);
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
      log('Error playing song: $e');
    }
  }

  /// Play a video as audio
  Future<void> playVideoAsAudio(Video video, {List<Video>? playlist, int? index}) async {
    _isVideoMode = true;
    _currentVideo = video;
    _currentSong = null;
    _currentVideoController.add(video);
    _currentSongController.add(null);

    if (playlist != null && index != null) {
      _playlist = playlist;
      _currentIndex = index;
      _preloadNextItem(index);
    }

    mediaItem.add(MediaItem(
      id: video.id,
      title: video.displayTitle,
      artist: video.artist,
      album: video.album,
      duration: Duration(milliseconds: video.duration),
      artUri: null,
    ));

    try {
      await _player.setFilePath(video.filePath);
      await _player.play();
    } catch (e) {
      log('Error playing video as audio: $e');
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
    final nextItem = _playlist[nextIndex];
    
    try {
      if (nextItem is Song) {
        await playSong(nextItem, playlist: _playlist as List<Song>, index: nextIndex);
      } else if (nextItem is Video) {
        await playVideoAsAudio(nextItem, playlist: _playlist as List<Video>, index: nextIndex);
      }
    } catch (e) {
      log('Error skipping to next: $e');
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty) return;
    final prevIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    final prevItem = _playlist[prevIndex];
    
    try {
      if (prevItem is Song) {
        await playSong(prevItem, playlist: _playlist as List<Song>, index: prevIndex);
      } else if (prevItem is Video) {
        await playVideoAsAudio(prevItem, playlist: _playlist as List<Video>, index: prevIndex);
      }
    } catch (e) {
      log('Error skipping to previous: $e');
    }
  }

  void _preloadNextItem(int currentIndex) {
    if (_playlist.isEmpty || _playlist.length <= 1) return;
    
    final nextIndex = (currentIndex + 1) % _playlist.length;
    _nextItem = _playlist[nextIndex];
    
    // Pre-buffer next item
    if (_nextItem is Song) {
      _player.setAudioSource(
        AudioSource.file((_nextItem as Song).filePath),
        preload: true,
      ).catchError((e) {
        log('Preload error: $e');
        return null;
      });
    } else if (_nextItem is Video) {
      _player.setAudioSource(
        AudioSource.file((_nextItem as Video).filePath),
        preload: true,
      ).catchError((e) {
        log('Preload error: $e');
        return null;
      });
    }
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
    await _currentVideoController.close();
  }
}

/// Initialize the audio service (supports both songs and video-as-audio)
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
