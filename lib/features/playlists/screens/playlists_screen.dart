import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/core/theme/app_theme.dart';
import 'package:play_beats/core/theme/neumorphic.dart';
import 'package:play_beats/data/models/playlist_model.dart';
import 'package:play_beats/data/models/song_model.dart';
import 'package:play_beats/features/common/widgets/artwork_widget.dart';
import 'package:play_beats/features/favorites/bloc/favorites_bloc.dart';
import 'package:play_beats/features/favorites/bloc/favorites_state.dart';
import 'package:play_beats/features/favorites/screens/favorites_screen.dart';
import 'package:play_beats/features/player/bloc/player_bloc.dart';
import 'package:play_beats/features/player/bloc/player_event.dart';
import 'package:play_beats/features/playlists/bloc/playlists_bloc.dart';
import 'package:play_beats/features/playlists/bloc/playlists_event.dart';
import 'package:play_beats/features/playlists/bloc/playlists_state.dart';
import 'package:play_beats/features/audios/bloc/audios_bloc.dart';
import 'package:play_beats/features/audios/bloc/audios_state.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    context.read<PlaylistsBloc>().add(LoadPlaylists());
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                Text(
                  'Playlists',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Spacer(),
                // Create playlist button
                GestureDetector(
                  onTap: () => _showCreatePlaylistDialog(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: Neu.circular(
                      color: c.surface,
                      bgColor: c.background,
                      shadowDark: c.shadowDark,
                      shadowLight: c.shadowLight,
                    ),
                    child: const Icon(Icons.add_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content - Grid with Favorites + Playlists
          Expanded(
            child: Column(
              children: [
                // Favorites Card
                _buildFavoritesCard(),
                // Custom Playlists Grid
                Expanded(
                  child: BlocConsumer<PlaylistsBloc, PlaylistsState>(
                    listener: (context, state) {
                      if (state is PlaylistsLoaded) {
                        _entryController.reset();
                        _entryController.forward();
                      }
                    },
                    builder: (context, state) {
                      if (state is PlaylistsLoading) {
                        return _buildShimmer();
                      }

                      if (state is PlaylistsError) {
                        return Center(
                          child: Text(
                            state.message,
                            style: TextStyle(color: c.textSecondary),
                          ),
                        );
                      }

                      if (state is PlaylistsLoaded) {
                        if (state.playlists.isEmpty) {
                          return _buildEmptyState();
                        }
                        return _buildPlaylistList(state.playlists);
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistList(List<Playlist> playlists) {
    final c = context.colors;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.82,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return GestureDetector(
          onTap: () => _navigateToPlaylistDetail(playlist),
          onLongPress: () => _showPlaylistOptions(playlist),
          child: Container(
            decoration: Neu.raised(
              radius: 20,
              color: c.surface,
              shadowDark: c.shadowDark,
              shadowLight: c.shadowLight,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.background,
                    boxShadow: [
                      BoxShadow(
                        color: c.shadowDark,
                        offset: const Offset(3, 3),
                        blurRadius: 6,
                      ),
                      BoxShadow(
                        color: c.shadowLight.withValues(alpha: 0.3),
                        offset: const Offset(-2, -2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Container(
                      color: c.accent.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.queue_music_rounded,
                        size: 45,
                        color: c.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    playlist.name,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${playlist.songIds.length} songs',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoritesCard() {
    final c = context.colors;
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, state) {
        if (state is FavoritesLoaded) {
          final favorites = state.favorites;
          final count = favorites.length;

          return GestureDetector(
            onTap: () {
              // Navigate to Favorites screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FavoritesScreen(),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              padding: const EdgeInsets.all(16),
              decoration: Neu.raised(
                radius: 20,
                color: c.surface,
                shadowDark: c.shadowDark,
                shadowLight: c.shadowLight,
              ),
              child: Row(
                children: [
                  // Heart icon container
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.background,
                      boxShadow: [
                        BoxShadow(
                          color: c.shadowDark,
                          offset: const Offset(3, 3),
                          blurRadius: 6,
                        ),
                        BoxShadow(
                          color: c.shadowLight.withValues(alpha: 0.3),
                          offset: const Offset(-2, -2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.favorite,
                      size: 30,
                      color: c.accent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Favorites',
                          style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          count > 0 ? '$count songs' : 'Tap to view favorites',
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow icon
                  Icon(
                    Icons.chevron_right,
                    color: c.iconDim,
                    size: 24,
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState() {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: Neu.circular(
              color: c.surface,
              bgColor: c.background,
              shadowDark: c.shadowDark,
              shadowLight: c.shadowLight,
            ),
            child: Icon(Icons.queue_music_rounded,
                color: c.iconDim, size: 36),
          ),
          const SizedBox(height: 20),
          Text(
            'No playlists yet',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first playlist to\norganize your favorite songs',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _showCreatePlaylistDialog(),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: c.accent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Create Playlist',
                    style: TextStyle(
                      color: c.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(Playlist playlist) {
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
              // Rename
              ListTile(
                leading: Icon(Icons.edit, color: c.textPrimary),
                title: Text('Rename', style: TextStyle(color: c.textPrimary)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showRenamePlaylistDialog(playlist);
                },
              ),
              // Delete
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red[400]),
                title: Text('Delete', style: TextStyle(color: Colors.red[400])),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showDeleteConfirmation(playlist);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showRenamePlaylistDialog(Playlist playlist) {
    final c = context.colors;
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Rename Playlist', style: TextStyle(color: c.textPrimary)),
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
                  context.read<PlaylistsBloc>().add(
                    RenamePlaylist(
                      playlistId: playlist.id,
                      newName: controller.text.trim(),
                    ),
                  );
                  Navigator.pop(dialogCtx);
                }
              },
              child: Text('Rename', style: TextStyle(color: c.accent)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(Playlist playlist) {
    final c = context.colors;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Icon(Icons.warning_amber_rounded,
              color: Colors.red[400], size: 48),
          title: Text('Delete Playlist?', style: TextStyle(color: c.textPrimary)),
          content: Text(
            'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.',
            style: TextStyle(color: c.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                context.read<PlaylistsBloc>().add(DeletePlaylist(playlist.id));
                Navigator.pop(dialogCtx);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red[400])),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmer() {
    final c = context.colors;
    final base =
        Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C1C34)
            : const Color(0xFFD4D4E0);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: base,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 10,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToPlaylistDetail(Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }

  void _showCreatePlaylistDialog() {
    final c = context.colors;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title:
              Text('New Playlist', style: TextStyle(color: c.textPrimary)),
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
                }
              },
              child: Text('Create', style: TextStyle(color: c.accent)),
            ),
          ],
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════
//  PLAYLIST DETAIL SCREEN
// ═════════════════════════════════════════════════════════════════
class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: Neu.circular(
                color: c.surface,
                bgColor: c.background,
                shadowDark: c.shadowDark,
                shadowLight: c.shadowLight,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
              ),
            ),
          ),
        ),
        title: Text(widget.playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: () => _playShuffle(),
          ),
        ],
      ),
      body: BlocBuilder<PlaylistsBloc, PlaylistsState>(
        builder: (context, state) {
          // Get all songs from AudiosBloc to map playlist song IDs to Song objects
          return BlocBuilder<AudiosBloc, AudiosState>(
            builder: (context, songsState) {
              List<Song> playlistSongs = [];
              if (songsState is AudiosLoaded) {
                final songMap = {
                  for (var song in songsState.allSongs) song.id: song
                };
                playlistSongs = widget.playlist.songIds
                    .map((id) => songMap[id])
                    .whereType<Song>()
                    .toList();
              }

              if (playlistSongs.isEmpty) {
                return _buildEmptyState();
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.82,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: playlistSongs.length,
                itemBuilder: (context, index) {
                  final song = playlistSongs[index];
                  return GestureDetector(
                    onTap: () {
                      context.read<PlayerBloc>().add(
                        PlaySong(song: song, playlist: playlistSongs),
                      );
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (context.mounted) {
                          Navigator.of(context).pushNamed('/player');
                        }
                      });
                    },
                    child: Container(
                      decoration: Neu.raised(
                        radius: 20,
                        color: c.surface,
                        shadowDark: c.shadowDark,
                        shadowLight: c.shadowLight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.background,
                              boxShadow: [
                                BoxShadow(
                                  color: c.shadowDark,
                                  offset: const Offset(3, 3),
                                  blurRadius: 6,
                                ),
                                BoxShadow(
                                  color: c.shadowLight.withValues(alpha: 0.3),
                                  offset: const Offset(-2, -2),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: ArtworkWidget(
                                id: song.numericId,
                                size: 90,
                                borderRadius: 45,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              song.displayTitle,
                              style: TextStyle(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artist,
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note_rounded, size: 64, color: c.iconDim),
          const SizedBox(height: 16),
          Text(
            'No songs in this playlist',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add songs from your library\nto build your playlist',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _playShuffle() {
    // Implementation would require access to all songs in the playlist
    // This is a simplified version
  }
}
