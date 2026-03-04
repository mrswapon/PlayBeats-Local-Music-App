import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:play_beats/app.dart';
import 'package:play_beats/data/services/audio_player_service.dart';
import 'package:play_beats/data/services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize services
  await HiveService.init();
  final audioService = await initAudioService();

  runApp(PlayBeatsApp(audioPlayerService: audioService));
}
