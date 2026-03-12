import 'package:play_beats/data/services/video_service.dart';

class VideoRepository {
  final VideoService _service = VideoService();

  Future<bool> requestPermission() => _service.requestPermission();

  Future<List<VideoFile>> getAllVideos() => _service.getAllVideos();
}
