import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/core/theme/app_theme.dart';
import 'package:play_beats/core/theme/neumorphic.dart';
import 'package:play_beats/features/common/widgets/song_tile.dart';
import 'package:play_beats/features/favorites/bloc/favorites_bloc.dart';
import 'package:play_beats/features/favorites/bloc/favorites_state.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;

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
        title: const Text('Favorites'),
      ),
      body: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, state) {
          if (state is FavoritesLoaded) {
            if (state.favorites.isEmpty) {
              return _buildEmptyState(c);
            }

            _entryController.reset();
            _entryController.forward();

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
                    curve: Interval(start, end, curve: Curves.easeOut),
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _entryController,
                      curve: Interval(start, end, curve: Curves.easeOut),
                    )),
                    child: SongTile(
                      song: state.favorites[index],
                      playlist: state.favorites,
                      index: index,
                      showMoreOptions: true,
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
    );
  }

  Widget _buildEmptyState(AppColors c) {
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
}
