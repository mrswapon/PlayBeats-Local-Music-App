import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_beats/data/services/hive_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(_loadSaved());

  static ThemeMode _loadSaved() {
    final idx = HiveService.settingsBox
        .get('theme_mode', defaultValue: 0);
    return idx == 1 ? ThemeMode.dark : ThemeMode.light;
  }

  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    HiveService.settingsBox
        .put('theme_mode', next == ThemeMode.dark ? 1 : 0);
    emit(next);
  }
}
