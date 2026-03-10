import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/core/theme/app_theme.dart';
import 'package:play_beats/core/theme/neumorphic.dart';
import 'package:play_beats/features/common/widgets/song_tile.dart';
import 'package:play_beats/features/favorites/bloc/favorites_bloc.dart';
import 'package:play_beats/features/favorites/bloc/favorites_state.dart';
import 'package:play_beats/features/player/bloc/player_bloc.dart';
import 'package:play_beats/features/player/bloc/player_event.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  int _prevCount = -1;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
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
          // ── Header with play-all/shuffle buttons ──
          BlocBuilder<FavoritesBloc, FavoritesState>(
            buildWhen: (prev, curr) {
              final prevLoaded = prev is FavoritesLoaded;
              final currLoaded = curr is FavoritesLoaded;
              if (!prevLoaded && !currLoaded) return false;
              if (prevLoaded != currLoaded) return true;
              return (prev as FavoritesLoaded).favorites.isEmpty !=
                  (curr as FavoritesLoaded).favorites.isEmpty;
            },
            builder: (context, state) {
              final loaded = state is FavoritesLoaded ? state : null;
              final hasSongs =
                  loaded != null && loaded.favorites.isNotEmpty;
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: _entryController,
                  curve: const Interval(0, 0.4, curve: Curves.easeOut),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      Text(
                        'Favorites',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Spacer(),
                      if (hasSongs) ...[
                        _actionCircle(
                          icon: Icons.play_arrow_rounded,
                          onTap: () {
                            final favs = loaded.favorites;
                            context.read<PlayerBloc>().add(
                                  PlaySong(
                                      song: favs.first, playlist: favs),
                                );
                          },
                          c: c,
                        ),
                        const SizedBox(width: 10),
                        _actionCircle(
                          icon: Icons.shuffle_rounded,
                          onTap: () {
                            final favs = loaded.favorites;
                            final shuffled = List.of(favs)..shuffle();
                            context.read<PlayerBloc>().add(
                                  PlaySong(
                                      song: shuffled.first,
                                      playlist: shuffled),
                                );
                          },
                          c: c,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // ── List ──
          Expanded(
            child: BlocConsumer<FavoritesBloc, FavoritesState>(
              listener: (context, state) {
                if (state is FavoritesLoaded) {
                  final count = state.favorites.length;
                  if (count != _prevCount) {
                    _entryController.reset();
                    _entryController.forward();
                    _prevCount = count;
                  }
                }
              },
              builder: (context, state) {
                if (state is FavoritesLoaded) {
                  if (state.favorites.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            size: 64,
                            color: c.iconDim,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No favorites yet',
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the heart icon on any song\nto add it to your favorites',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: state.favorites.length,
                    itemBuilder: (context, index) {
                      final delay = index * 0.06;
                      final start = (0.15 + delay).clamp(0.0, 1.0);
                      final end = (0.5 + delay).clamp(0.0, 1.0);
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _entryController,
                          curve:
                              Interval(start, end, curve: Curves.easeOut),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.25),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _entryController,
                            curve: Interval(start, end,
                                curve: Curves.easeOut),
                          )),
                          child: SongTile(
                            song: state.favorites[index],
                            playlist: state.favorites,
                            index: index,
                          ),
                        ),
                      );
                    },
                  );
                }

                return Center(
                  child: CircularProgressIndicator(color: c.accent),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCircle({
    required IconData icon,
    required VoidCallback onTap,
    required AppColors c,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: Neu.circular(
          color: c.surface,
          bgColor: c.background,
          shadowDark: c.shadowDark,
          shadowLight: c.shadowLight,
        ),
        child: Icon(icon, color: c.textSecondary, size: 20),
      ),
    );
  }
}
