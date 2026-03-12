import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/data/models/video_model.dart';
import 'package:play_beats/data/repositories/video_repository.dart';
import 'package:play_beats/features/videos/bloc/videos_event.dart';
import 'package:play_beats/features/videos/bloc/videos_state.dart';

class VideosBloc extends Bloc<VideosEvent, VideosState> {
  final VideoRepository repository;

  VideosBloc({required this.repository}) : super(VideosInitial()) {
    on<LoadVideos>(_onLoadVideos);
    on<RefreshVideos>(_onRefreshVideos);
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
      final videoFiles = await repository.getAllVideos();
      // Convert VideoFile to Video model
      final videos = videoFiles.map((vf) => Video(
        id: vf.id,
        title: vf.title,
        artist: vf.artist,
        filePath: vf.filePath,
        duration: vf.duration,
        album: vf.album,
        albumId: vf.albumId,
      )).toList();
      emit(VideosLoaded(videos));
    } catch (e) {
      emit(VideosError(e.toString()));
    }
  }

  Future<void> _onRefreshVideos(
    RefreshVideos event,
    Emitter<VideosState> emit,
  ) async {
    try {
      final videoFiles = await repository.getAllVideos();
      final videos = videoFiles.map((vf) => Video(
        id: vf.id,
        title: vf.title,
        artist: vf.artist,
        filePath: vf.filePath,
        duration: vf.duration,
        album: vf.album,
        albumId: vf.albumId,
      )).toList();
      emit(VideosLoaded(videos));
    } catch (e) {
      emit(VideosError(e.toString()));
    }
  }
}
