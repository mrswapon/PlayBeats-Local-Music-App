import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

class Video extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String filePath;
  final int duration; // milliseconds
  final String album;
  final int albumId;
  final String? thumbnailPath;
  final String? customTitle;

  const Video({
    required this.id,
    required this.title,
    required this.artist,
    required this.filePath,
    this.duration = 0,
    this.album = '',
    this.albumId = 0,
    this.thumbnailPath,
    this.customTitle,
  });

  /// Get the display title (custom title if set, otherwise original title)
  String get displayTitle => customTitle?.isNotEmpty == true ? customTitle! : title;

  /// Check if the video has a custom title
  bool get hasCustomTitle => customTitle?.isNotEmpty == true;

  /// Numeric ID for artwork queries
  int get numericId => int.tryParse(id) ?? 0;

  /// Formatted duration string (mm:ss)
  String get durationFormatted {
    final d = Duration(milliseconds: duration);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'filePath': filePath,
      'duration': duration,
      'album': album,
      'albumId': albumId,
      'thumbnailPath': thumbnailPath,
      'customTitle': customTitle,
    };
  }

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      filePath: json['filePath'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      album: json['album'] as String? ?? '',
      albumId: json['albumId'] as int? ?? 0,
      thumbnailPath: json['thumbnailPath'] as String?,
      customTitle: json['customTitle'] as String?,
    );
  }

  Video copyWith({
    String? id,
    String? title,
    String? artist,
    String? filePath,
    int? duration,
    String? album,
    int? albumId,
    String? thumbnailPath,
    String? customTitle,
  }) {
    return Video(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      customTitle: customTitle ?? this.customTitle,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, artist, filePath, duration, album, albumId, thumbnailPath, customTitle];
}

class VideoAdapter extends TypeAdapter<Video> {
  @override
  final int typeId = 2;

  @override
  Video read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return Video.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, Video obj) {
    writer.writeMap(obj.toJson());
  }
}
