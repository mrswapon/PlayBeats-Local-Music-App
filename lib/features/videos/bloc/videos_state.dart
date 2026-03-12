import 'package:equatable/equatable.dart';
import 'package:play_beats/data/models/video_model.dart';

abstract class VideosState extends Equatable {
  const VideosState();

  @override
  List<Object?> get props => [];
}

class VideosInitial extends VideosState {}

class VideosLoading extends VideosState {}

class VideosLoaded extends VideosState {
  final List<Video> videos;

  const VideosLoaded(this.videos);

  @override
  List<Object?> get props => [videos];
}

class VideosPermissionDenied extends VideosState {}

class VideosError extends VideosState {
  final String message;

  const VideosError(this.message);

  @override
  List<Object?> get props => [message];
}
