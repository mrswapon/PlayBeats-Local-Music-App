import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/data/services/hive_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  Future<void> loadSavedTheme() async {
    final box = await HiveService.settingsBox;
    final idx = box.get('theme_mode', defaultValue: 0);
    emit(idx == 1 ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final box = await HiveService.settingsBox;
    await box.put('theme_mode', next == ThemeMode.dark ? 1 : 0);
    emit(next);
  }
}
