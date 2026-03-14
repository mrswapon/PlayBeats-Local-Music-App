import 'package:hive_flutter/hive_flutter.dart';
import 'package:play_beats/data/models/song_model.dart';
import 'package:play_beats/data/models/playlist_model.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(SongAdapter());
    Hive.registerAdapter(PlaylistAdapter());
    await Hive.openBox<Song>('favorites');
    await Hive.openBox<Playlist>('playlists');
    await Hive.openBox('settings');

    // Migration: clear old favorites that have no filePath (stale YouTube data)
    final favBox = Hive.box<Song>('favorites');
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
      Hive.box<Song>('favorites');

  static Box<Playlist> get playlistsBox =>
      Hive.box<Playlist>('playlists');

  static Box get settingsBox => Hive.box('settings');

  static bool get isOnboardingComplete =>
      settingsBox.get('onboarding_complete', defaultValue: false);

  static Future<void> setOnboardingComplete() =>
      settingsBox.put('onboarding_complete', true);
}
