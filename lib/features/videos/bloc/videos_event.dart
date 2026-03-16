import 'package:equatable/equatable.dart';
import 'package:play_beats/data/models/video_model.dart';

abstract class VideosEvent extends Equatable {
  const VideosEvent();

  @override
  List<Object?> get props => [];
}

class LoadVideos extends VideosEvent {}

class RefreshVideos extends VideosEvent {}

class ClearVideoCache extends VideosEvent {}

class PlayVideo extends VideosEvent {
  final Video video;

  const PlayVideo(this.video);

  @override
  List<Object?> get props => [video];
}
