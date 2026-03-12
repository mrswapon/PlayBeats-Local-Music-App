import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerService extends ChangeNotifier {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isDisposed = false;

  VideoPlayerController? get controller => _controller;
  ChewieController? get chewieController => _chewieController;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;

  Future<void> initialize(String filePath) async {
    // Clean up any existing controller first
    if (_controller != null) {
      _controller!.removeListener(_onVideoChanged);
      await _controller!.dispose();
      _chewieController?.dispose();
      _controller = null;
      _chewieController = null;
    }

    _controller = VideoPlayerController.file(File(filePath));
    await _controller!.initialize();

    _duration = _controller!.value.duration;

    _chewieController = ChewieController(
      videoPlayerController: _controller!,
      autoPlay: true,
      looping: false,
      showControlsOnInitialize: true,
      allowFullScreen: true,
      allowMuting: true,
      allowPlaybackSpeedChanging: true,
    );

    _controller!.addListener(_onVideoChanged);
    notifyListeners();
  }

  void _onVideoChanged() {
    if (_controller != null && !_isDisposed) {
      _isPlaying = _controller!.value.isPlaying;
      _position = _controller!.value.position;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  Future<void> play() async {
    if (_controller != null) {
      await _controller!.play();
    }
  }

  Future<void> pause() async {
    if (_controller != null) {
      await _controller!.pause();
    }
  }

  Future<void> seekTo(Duration position) async {
    if (_controller != null) {
      await _controller!.seekTo(position);
    }
  }

  void setPlaybackSpeed(double speed) {
    if (_controller != null) {
      _controller!.setPlaybackSpeed(speed);
    }
  }

  @override
  // ignore: must_call_super
  void dispose() {
    if (_isDisposed) return; // Prevent double disposal
    _isDisposed = true;
    
    _controller?.removeListener(_onVideoChanged);
    _controller?.dispose();
    _chewieController?.dispose();
    _controller = null;
    _chewieController = null;
    _isPlaying = false;
    _position = Duration.zero;
  }
}
