import 'package:play_beats/data/models/video_model.dart';
import 'package:play_beats/data/services/video_service.dart';

class VideoRepository {
  final VideoService _service = VideoService();

  Future<bool> requestPermission() => _service.requestPermission();

  Future<List<Video>> getAllVideos() => _service.getAllVideos();
}
