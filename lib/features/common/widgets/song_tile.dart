import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/core/theme/app_theme.dart';
import 'package:play_beats/core/theme/neumorphic.dart';
import 'package:play_beats/data/models/song_model.dart';
import 'package:play_beats/data/repositories/song_metadata_repository.dart';
import 'package:play_beats/features/common/widgets/artwork_widget.dart';
import 'package:play_beats/features/favorites/bloc/favorites_bloc.dart';
import 'package:play_beats/features/favorites/bloc/favorites_event.dart';
import 'package:play_beats/features/favorites/bloc/favorites_state.dart';
import 'package:play_beats/features/player/bloc/player_bloc.dart';
import 'package:play_beats/features/player/bloc/player_event.dart';
import 'package:play_beats/features/playlists/bloc/playlists_bloc.dart';
import 'package:play_beats/features/playlists/bloc/playlists_event.dart';
import 'package:play_beats/features/playlists/bloc/playlists_state.dart';

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
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: Neu.raised(
            radius: 18,
            color: c.surface,
            shadowDark: c.shadowDark,
            shadowLight: c.shadowLight,
          ),
          child: Row(
            children: [
              // Circular artwork thumbnail
              Container(
                width: 50,
                height: 50,
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
                    size: 50,
                    borderRadius: 25,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Song info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            song.displayTitle,
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (song.hasCustomTitle) ...[
                          Icon(
                            Icons.edit,
                            size: 12,
                            color: c.iconDim,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            song.artist,
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (song.duration > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            song.durationFormatted,
                            style: TextStyle(
                              color: c.iconDim,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
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
                      size: 20,
                    ),
                  );
                },
              ),

              // More options button
              if (showMoreOptions) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showOptionsSheet(context),
                  child: Icon(
                    Icons.more_vert,
                    color: c.iconDim,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: c.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Rename song
              ListTile(
                leading: Icon(Icons.edit, color: c.textPrimary),
                title: Text(
                  song.hasCustomTitle ? 'Edit Name' : 'Rename',
                  style: TextStyle(color: c.textPrimary),
                ),
                subtitle: song.hasCustomTitle
                    ? Text(
                        'Custom: ${song.displayTitle}',
                        style: TextStyle(color: c.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showRenameDialog(context);
                },
              ),
              // Add to playlist
              ListTile(
                leading: Icon(Icons.playlist_add, color: c.textPrimary),
                title: Text('Add to Playlist',
                    style: TextStyle(color: c.textPrimary)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showPlaylistSelectionSheet(context);
                },
              ),
              // Remove from favorites (if favorited)
              BlocBuilder<FavoritesBloc, FavoritesState>(
                builder: (context, favState) {
                  final isFav = favState is FavoritesLoaded &&
                      favState.isFavorite(song.id);
                  if (!isFav) return const SizedBox.shrink();
                  return ListTile(
                    leading: Icon(Icons.favorite, color: c.accent),
                    title:
                        Text('Remove from Favorites',
                            style: TextStyle(color: c.accent)),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      context
                          .read<FavoritesBloc>()
                          .add(RemoveFromFavorites(song.id));
                    },
                  );
                },
              ),
              // Delete song
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red[400]),
                title: Text('Delete Song',
                    style: TextStyle(color: Colors.red[400])),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showDeleteConfirmation(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showPlaylistSelectionSheet(BuildContext context) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: c.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Row(
                  children: [
                    Text('Select Playlist',
                        style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    // Create new playlist button
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _showCreatePlaylistDialog(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add,
                                color: c.accent, size: 16),
                            const SizedBox(width: 4),
                            Text('New',
                                style: TextStyle(
                                    color: c.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              BlocBuilder<PlaylistsBloc, PlaylistsState>(
                builder: (context, state) {
                  if (state is PlaylistsLoaded) {
                    final playlists = state.playlists;
                    if (playlists.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No playlists yet.\nCreate one to add songs.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.textSecondary),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        final isSongInPlaylist =
                            playlist.songIds.contains(song.id);
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: Neu.circular(
                              color: c.surface,
                              bgColor: c.background,
                              shadowDark: c.shadowDark,
                              shadowLight: c.shadowLight,
                            ),
                            child: Icon(Icons.queue_music,
                                color: c.textSecondary, size: 18),
                          ),
                          title: Text(
                            playlist.name,
                            style: TextStyle(color: c.textPrimary),
                          ),
                          subtitle: Text(
                            '${playlist.songIds.length} songs',
                            style: TextStyle(color: c.textSecondary),
                          ),
                          trailing: isSongInPlaylist
                              ? Icon(Icons.check, color: c.accent)
                              : null,
                          onTap: () {
                            if (!isSongInPlaylist) {
                              context.read<PlaylistsBloc>().add(
                                    AddSongToPlaylist(
                                      playlistId: playlist.id,
                                      songId: song.id,
                                    ),
                                  );
                            }
                            Navigator.pop(sheetCtx);
                          },
                        );
                      },
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final c = context.colors;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('New Playlist',
              style: TextStyle(color: c.textPrimary)),
          content: TextField(
            controller: controller,
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'Playlist name',
              hintStyle: TextStyle(color: c.textSecondary),
              filled: true,
              fillColor: c.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  context
                      .read<PlaylistsBloc>()
                      .add(CreatePlaylist(controller.text.trim()));
                  Navigator.pop(dialogCtx);
                  // Show playlist selection after creating
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (context.mounted) {
                      _showPlaylistSelectionSheet(context);
                    }
                  });
                }
              },
              child: Text('Create', style: TextStyle(color: c.accent)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final c = context.colors;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Icon(Icons.warning_amber_rounded,
              color: Colors.red[400], size: 48),
          title: Text('Delete Song?',
              style: TextStyle(color: c.textPrimary)),
          content: Text(
            'This will remove "${song.title}" from your device storage. This action cannot be undone.',
            style: TextStyle(color: c.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                // Note: Actual file deletion would require platform channel
                // or a package like flutter_file_manager
                // For now, we'll just show a message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('File deletion requires additional setup'),
                    backgroundColor: c.textSecondary,
                  ),
                );
              },
              child: Text('Delete',
                  style: TextStyle(color: Colors.red[400])),
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context) {
    final c = context.colors;
    final controller = TextEditingController(text: song.displayTitle);
    final metadataRepo = context.read<SongMetadataRepository>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Rename Song',
              style: TextStyle(color: c.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                style: TextStyle(color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter new name',
                  hintStyle: TextStyle(color: c.textSecondary),
                  filled: true,
                  fillColor: c.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.edit, color: c.iconDim),
                ),
                autofocus: true,
                maxLength: 100,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  // Submit on enter
                },
              ),
              if (song.hasCustomTitle) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: c.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Original: ${song.title}',
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            if (song.hasCustomTitle)
              TextButton(
                onPressed: () async {
                  await metadataRepo.clearCustomTitle(song.id);
                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Restored original name'),
                        backgroundColor: c.textSecondary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text('Reset',
                    style: TextStyle(color: c.textSecondary)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != song.title) {
                  await metadataRepo.setCustomTitle(song.id, newName);
                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          newName.isEmpty
                              ? 'Restored original name'
                              : 'Renamed to "$newName"',
                        ),
                        backgroundColor: c.accent,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } else if (newName.isEmpty) {
                  // Clear custom title if empty
                  await metadataRepo.clearCustomTitle(song.id);
                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Restored original name'),
                        backgroundColor: c.textSecondary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  Navigator.pop(dialogCtx);
                }
              },
              child: Text('Save', style: TextStyle(color: c.accent)),
            ),
          ],
        );
      },
    );
  }
}
