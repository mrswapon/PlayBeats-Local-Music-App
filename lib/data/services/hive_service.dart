import 'package:hive_flutter/hive_flutter.dart';
import 'package:play_beats/data/models/song_model.dart';
import 'package:play_beats/data/models/playlist_model.dart';

class HiveService {
  static bool _initialized = false;
  static Box<Song>? _favoritesBox;
  static Box<Playlist>? _playlistsBox;
  static Box? _settingsBox;

  static Future<void> init() async {
    if (_initialized) return;
    
    await Hive.initFlutter();
    Hive.registerAdapter(SongAdapter());
    Hive.registerAdapter(PlaylistAdapter());
    
    // Open boxes lazily - only when needed
    _initialized = true;
  }

  static Future<void> _ensureInitialized() async {
    if (!_initialized) await init();
    
    // Open boxes on first access
    _favoritesBox ??= await Hive.openBox<Song>('favorites');
    _playlistsBox ??= await Hive.openBox<Playlist>('playlists');
    _settingsBox ??= await Hive.openBox('settings');
    
    // One-time migration: clear old favorites that have no filePath
    if (_favoritesBox != null) {
      final staleKeys = <dynamic>[];
      for (final key in _favoritesBox!.keys) {
        final song = _favoritesBox!.get(key);
        if (song != null && song.filePath.isEmpty) {
          staleKeys.add(key);
        }
      }
      if (staleKeys.isNotEmpty) {
        await _favoritesBox!.deleteAll(staleKeys);
      }
    }
  }

  static Future<Box<Song>> get favoritesBox async {
    await _ensureInitialized();
    return _favoritesBox!;
  }

  static Future<Box<Playlist>> get playlistsBox async {
    await _ensureInitialized();
    return _playlistsBox!;
  }

  static Future<Box> get settingsBox async {
    await _ensureInitialized();
    return _settingsBox!;
  }

  static Future<bool> get isOnboardingComplete async {
    final box = await settingsBox;
    return box.get('onboarding_complete', defaultValue: false);
  }

  static Future<void> setOnboardingComplete() async {
    final box = await settingsBox;
    await box.put('onboarding_complete', true);
  }
}
