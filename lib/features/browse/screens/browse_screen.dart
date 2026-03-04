import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:play_beats/core/theme/app_theme.dart';
import 'package:play_beats/core/theme/neumorphic.dart';
import 'package:play_beats/core/theme/theme_cubit.dart';
import 'package:play_beats/features/browse/bloc/browse_bloc.dart';
import 'package:play_beats/features/browse/bloc/browse_event.dart';
import 'package:play_beats/features/browse/bloc/browse_state.dart';
import 'package:play_beats/features/common/widgets/artwork_widget.dart';
import 'package:play_beats/features/common/widgets/song_tile.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => BrowseScreenState();
}

class BrowseScreenState extends State<BrowseScreen> {
  bool _showArtists = true;

  /// Called by AppShell when this tab becomes visible for the first time.
  void loadIfNeeded() {
    final state = context.read<BrowseBloc>().state;
    if (state is BrowseInitial) {
      context.read<BrowseBloc>().add(LoadArtists());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Browse',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                // ── Theme toggle ──
                BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, mode) {
                    return GestureDetector(
                      onTap: () => context.read<ThemeCubit>().toggle(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: Neu.circular(
                          size: 40,
                          color: c.surface,
                          bgColor: c.background,
                          shadowDark: c.shadowDark,
                          shadowLight: c.shadowLight,
                        ),
                        child: Icon(
                          mode == ThemeMode.dark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: c.textSecondary,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Toggle / back header ──
          BlocBuilder<BrowseBloc, BrowseState>(
            builder: (context, state) {
              final showBack = state is BrowseSongsLoaded;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    if (showBack) ...[
                      GestureDetector(
                        onTap: () =>
                            context.read<BrowseBloc>().add(BackToBrowse()),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: Neu.circular(
                            size: 36,
                            color: c.surface,
                            bgColor: c.background,
                            shadowDark: c.shadowDark,
                            shadowLight: c.shadowLight,
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              color: c.textSecondary, size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.title,
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else ...[
                      _buildChip('Artists', _showArtists, () {
                        setState(() => _showArtists = true);
                        context.read<BrowseBloc>().add(LoadArtists());
                      }),
                      const SizedBox(width: 10),
                      _buildChip('Albums', !_showArtists, () {
                        setState(() => _showArtists = false);
                        context.read<BrowseBloc>().add(LoadAlbums());
                      }),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // ── Content ──
          Expanded(
            child: BlocBuilder<BrowseBloc, BrowseState>(
              builder: (context, state) {
                if (state is BrowseLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: c.accent),
                  );
                }

                if (state is BrowseError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: TextStyle(color: c.textSecondary),
                    ),
                  );
                }

                if (state is BrowseArtistsLoaded) {
                  if (state.artists.isEmpty) {
                    return _buildEmpty('No artists found');
                  }
                  return _buildArtistList(state.artists);
                }

                if (state is BrowseAlbumsLoaded) {
                  if (state.albums.isEmpty) {
                    return _buildEmpty('No albums found');
                  }
                  return _buildAlbumList(state.albums);
                }

                if (state is BrowseSongsLoaded) {
                  if (state.songs.isEmpty) {
                    return _buildEmpty('No songs found');
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: state.songs.length,
                    itemBuilder: (context, index) {
                      return SongTile(
                        song: state.songs[index],
                        playlist: state.songs,
                        index: index,
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: selected
            ? Neu.raised(
                radius: 20,
                color: c.surface,
                shadowDark: c.shadowDark,
                shadowLight: c.shadowLight,
              )
            : Neu.pressed(
                radius: 20,
                color: c.background,
                shadowDark: c.shadowDark,
                shadowLight: c.shadowLight,
              ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c.accent : c.iconDim,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(String message) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_music_rounded, size: 64, color: c.iconDim),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistList(List<ArtistModel> artists) {
    final c = context.colors;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        final name = (artist.artist == '<unknown>')
            ? 'Unknown Artist'
            : artist.artist;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              context.read<BrowseBloc>().add(
                    LoadArtistSongs(artistId: artist.id, artistName: name),
                  );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: Neu.raised(
                radius: 18,
                color: c.surface,
                shadowDark: c.shadowDark,
                shadowLight: c.shadowLight,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
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
                        id: artist.id,
                        size: 48,
                        borderRadius: 24,
                        type: ArtworkType.ARTIST,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${artist.numberOfTracks ?? 0} songs',
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: c.iconDim, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumList(List<AlbumModel> albums) {
    final c = context.colors;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        final name = (album.album == '<unknown>')
            ? 'Unknown Album'
            : album.album;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              context.read<BrowseBloc>().add(
                    LoadAlbumSongs(albumId: album.id, albumName: name),
                  );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: Neu.raised(
                radius: 18,
                color: c.surface,
                shadowDark: c.shadowDark,
                shadowLight: c.shadowLight,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
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
                        id: album.id,
                        size: 48,
                        borderRadius: 24,
                        type: ArtworkType.ALBUM,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${album.numOfSongs} songs',
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: c.iconDim, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
