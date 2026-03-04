import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:on_audio_query/on_audio_query.dart' as oaq;

class Song extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String filePath;
  final int duration; // milliseconds
  final String album;
  final int albumId;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.filePath,
    this.duration = 0,
    this.album = '',
    this.albumId = 0,
  });

  factory Song.fromDeviceSong(oaq.SongModel deviceSong) {
    return Song(
      id: deviceSong.id.toString(),
      title: deviceSong.title,
      artist: (deviceSong.artist == null || deviceSong.artist == '<unknown>')
          ? 'Unknown Artist'
          : deviceSong.artist!,
      filePath: deviceSong.data,
      duration: deviceSong.duration ?? 0,
      album: (deviceSong.album == null || deviceSong.album == '<unknown>')
          ? 'Unknown Album'
          : deviceSong.album!,
      albumId: deviceSong.albumId ?? 0,
    );
  }

  /// Numeric ID for artwork queries with on_audio_query
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
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      filePath: json['filePath'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      album: json['album'] as String? ?? '',
      albumId: json['albumId'] as int? ?? 0,
    );
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? filePath,
    int? duration,
    String? album,
    int? albumId,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, artist, filePath, duration, album, albumId];
}

class SongAdapter extends TypeAdapter<Song> {
  @override
  final int typeId = 0;

  @override
  Song read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return Song.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, Song obj) {
    writer.writeMap(obj.toJson());
  }
}
