import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/core/theme/app_theme.dart';
import 'package:play_beats/core/theme/neumorphic.dart';
import 'package:play_beats/data/models/song_model.dart';
import 'package:play_beats/features/common/widgets/artwork_widget.dart';
import 'package:play_beats/features/favorites/bloc/favorites_bloc.dart';
import 'package:play_beats/features/favorites/bloc/favorites_event.dart';
import 'package:play_beats/features/favorites/bloc/favorites_state.dart';
import 'package:play_beats/features/player/bloc/player_bloc.dart';
import 'package:play_beats/features/player/bloc/player_event.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final List<Song> playlist;
  final int index;
  final bool showMoreOptions;

  const SongTile({
    super.key,
    required this.song,
    this.playlist = const [],
    this.index = 0,
    this.showMoreOptions = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      child: GestureDetector(
        onTap: () {
          context.read<PlayerBloc>().add(
                PlaySong(song: song, playlist: playlist),
              );
          // Navigate to player screen after a short delay
          Future.delayed(const Duration(milliseconds: 20), () {
            if (context.mounted) {
              Navigator.of(context).pushNamed('/player');
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: Neu.raised(
            radius: 18,
            color: c.surface,
            shadowDark: c.shadowDark,
            shadowLight: c.shadowLight,
          ),
          child: Row(
            children: [
              // Circular artwork thumbnail
              SizedBox(
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.background,
                    boxShadow: [
                      BoxShadow(
                        color: c.shadowDark,
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                      BoxShadow(
                        color: c.shadowLight.withValues(alpha: 0.3),
                        offset: const Offset(-2, -2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: ArtworkWidget(
                      id: song.numericId,
                      size: 40,
                      borderRadius: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Song info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.displayTitle,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Favorite button
              BlocBuilder<FavoritesBloc, FavoritesState>(
                builder: (context, favState) {
                  final isFav = favState is FavoritesLoaded &&
                      favState.isFavorite(song.id);
                  return GestureDetector(
                    onTap: () {
                      if (isFav) {
                        context
                            .read<FavoritesBloc>()
                            .add(RemoveFromFavorites(song.id));
                      } else {
                        context
                            .read<FavoritesBloc>()
                            .add(AddToFavorites(song));
                      }
                    },
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? c.accent : c.iconDim,
                      size: 16,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
