import 'package:hive_flutter/hive_flutter.dart';
import 'package:play_beats/core/constants/app_constants.dart';
import 'package:play_beats/data/models/song_model.dart';
import 'package:play_beats/data/models/playlist_model.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(SongAdapter());
    Hive.registerAdapter(PlaylistAdapter());
    await Hive.openBox<Song>(AppConstants.favoritesBox);
    await Hive.openBox<Playlist>(AppConstants.playlistsBox);
    await Hive.openBox(AppConstants.settingsBox);

    // Migration: clear old favorites that have no filePath (stale YouTube data)
    final favBox = Hive.box<Song>(AppConstants.favoritesBox);
    final staleKeys = <dynamic>[];
    for (final key in favBox.keys) {
      final song = favBox.get(key);
      if (song != null && song.filePath.isEmpty) {
        staleKeys.add(key);
      }
    }
    if (staleKeys.isNotEmpty) {
      await favBox.deleteAll(staleKeys);
    }
  }

  static Box<Song> get favoritesBox =>
      Hive.box<Song>(AppConstants.favoritesBox);

  static Box<Playlist> get playlistsBox =>
      Hive.box<Playlist>(AppConstants.playlistsBox);

  static Box get settingsBox => Hive.box(AppConstants.settingsBox);

  static bool get isOnboardingComplete =>
      settingsBox.get(AppConstants.onboardingCompleteKey, defaultValue: false);

  static Future<void> setOnboardingComplete() =>
      settingsBox.put(AppConstants.onboardingCompleteKey, true);
}
