import 'package:on_audio_query/on_audio_query.dart';
import 'package:play_beats/data/services/video_service.dart';

class VideoRepository {
  final VideoService _service = VideoService();

  Future<bool> requestPermission() => _service.requestPermission();

  Future<List<SongModel>> getAllVideos() => _service.getAllVideos();
}
