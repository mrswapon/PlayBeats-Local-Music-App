import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/core/constants/app_constants.dart';
import 'package:play_beats/core/theme/app_theme.dart';
import 'package:play_beats/core/theme/theme_cubit.dart';
import 'package:play_beats/data/repositories/favorites_repository.dart';
import 'package:play_beats/data/repositories/local_music_repository.dart';
import 'package:play_beats/data/repositories/playlists_repository.dart';
import 'package:play_beats/data/repositories/song_metadata_repository.dart';
import 'package:play_beats/data/repositories/video_repository.dart';
import 'package:play_beats/data/services/audio_player_service.dart';
import 'package:play_beats/features/audios/bloc/audios_bloc.dart';
import 'package:play_beats/features/browse/bloc/browse_bloc.dart';
import 'package:play_beats/features/favorites/bloc/favorites_bloc.dart';
import 'package:play_beats/features/player/bloc/player_bloc.dart';
import 'package:play_beats/features/player/screens/player_screen.dart';
import 'package:play_beats/features/playlists/bloc/playlists_bloc.dart';
import 'package:play_beats/features/splash/screens/splash_screen.dart';
import 'package:play_beats/features/videos/bloc/videos_bloc.dart';

class PlayBeatsApp extends StatelessWidget {
  final AudioPlayerService audioPlayerService;

  const PlayBeatsApp({super.key, required this.audioPlayerService});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AudioPlayerService>.value(
          value: audioPlayerService,
        ),
        RepositoryProvider(create: (_) => LocalMusicRepository()),
        RepositoryProvider(create: (_) => FavoritesRepository()),
        RepositoryProvider(create: (_) => PlaylistsRepository()),
        RepositoryProvider(create: (_) => VideoRepository()),
        RepositoryProvider(create: (_) => SongMetadataRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ThemeCubit()..loadSavedTheme(),
          ),
          // Lazy load BLoCs - only initialize when accessed
          BlocProvider(
            lazy: true,
            create: (context) => AudiosBloc(
              repository: context.read<LocalMusicRepository>(),
            ),
          ),
          BlocProvider(
            lazy: true,
            create: (context) => PlayerBloc(
              audioService: context.read<AudioPlayerService>(),
            ),
          ),
          BlocProvider(
            lazy: true,
            create: (context) => FavoritesBloc(
              repository: context.read<FavoritesRepository>(),
            ),
          ),
          BlocProvider(
            lazy: true,
            create: (context) => BrowseBloc(
              repository: context.read<LocalMusicRepository>(),
            ),
          ),
          BlocProvider(
            lazy: true,
            create: (context) => PlaylistsBloc(
              repository: context.read<PlaylistsRepository>(),
            ),
          ),
          BlocProvider(
            lazy: true,
            create: (context) => VideosBloc(
              repository: context.read<VideoRepository>(),
            ),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: const SplashScreen(),
              routes: {
                '/player': (context) => const PlayerScreen(),
              },
            );
          },
        ),
      ),
    );
  }
}
