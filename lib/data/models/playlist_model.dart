import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

class Playlist extends Equatable {
  final String id;
  final String name;
  final List<String> songIds; // Ordered list of song IDs
  final DateTime createdAt;
  final DateTime updatedAt;

  const Playlist({
    required this.id,
    required this.name,
    required this.songIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Playlist.create(String name) {
    final now = DateTime.now();
    return Playlist(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      songIds: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  Playlist copyWith({
    String? id,
    String? name,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songIds': songIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      songIds: List<String>.from(json['songIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, name, songIds, createdAt, updatedAt];
}

class PlaylistAdapter extends TypeAdapter<Playlist> {
  @override
  final int typeId = 1;

  @override
  Playlist read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return Playlist.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, Playlist obj) {
    writer.writeMap(obj.toJson());
  }
}
