import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:play_beats/core/theme/app_theme.dart';

class ArtworkWidget extends StatelessWidget {
  final int id;
  final double size;
  final double borderRadius;
  final ArtworkType type;

  const ArtworkWidget({
    super.key,
    required this.id,
    this.size = 56,
    this.borderRadius = 8,
    this.type = ArtworkType.AUDIO,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return QueryArtworkWidget(
      id: id,
      type: type,
      artworkWidth: size,
      artworkHeight: size,
      artworkBorder: BorderRadius.circular(borderRadius),
      artworkFit: BoxFit.cover,
      nullArtworkWidget: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(
          Icons.music_note,
          size: size * 0.4,
          color: c.textSecondary,
        ),
      ),
    );
  }
}
