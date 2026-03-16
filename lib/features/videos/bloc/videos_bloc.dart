import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/data/repositories/video_repository.dart';
import 'package:play_beats/features/videos/bloc/videos_event.dart';
import 'package:play_beats/features/videos/bloc/videos_state.dart';

class VideosBloc extends Bloc<VideosEvent, VideosState> {
  final VideoRepository repository;

  VideosBloc({required this.repository}) : super(VideosInitial()) {
    on<LoadVideos>(_onLoadVideos);
    on<RefreshVideos>(_onRefreshVideos);
    on<ClearVideoCache>(_onClearVideoCache);
  }

  Future<void> _onLoadVideos(
    LoadVideos event,
    Emitter<VideosState> emit,
  ) async {
    emit(VideosLoading());

    final granted = await repository.requestPermission();
    if (!granted) {
      emit(VideosPermissionDenied());
      return;
    }

    try {
      final videos = await repository.getAllVideos();
      emit(VideosLoaded(videos));
    } catch (e) {
      emit(VideosError(e.toString()));
    }
  }

  Future<void> _onRefreshVideos(
    RefreshVideos event,
    Emitter<VideosState> emit,
  ) async {
    if (state is VideosLoaded) {
      // Emit current state while refreshing
      emit((state as VideosLoaded).copyWith(isRefreshing: true));
    }
    
    try {
      await repository.clearCache();
      final videos = await repository.getAllVideos();
      emit(VideosLoaded(videos, isRefreshing: false));
    } catch (e) {
      emit(VideosError(e.toString()));
    }
  }

  Future<void> _onClearVideoCache(
    ClearVideoCache event,
    Emitter<VideosState> emit,
  ) async {
    try {
      await repository.clearCache();
    } catch (e) {
      log('Error clearing cache: $e');
    }
  }
}
