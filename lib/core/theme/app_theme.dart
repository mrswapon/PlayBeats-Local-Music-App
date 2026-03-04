import 'package:flutter/material.dart';

// ─── Theme-aware color set carried via ThemeExtension ──────────
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color shadowDark;
  final Color shadowLight;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color iconDim;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.shadowDark,
    required this.shadowLight,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconDim,
  });

  // ── Dark palette ──
  static const dark = AppColors(
    background: Color(0xFF1E1E2E),
    surface: Color(0xFF2A2A3C),
    surfaceLight: Color(0xFF323246),
    shadowDark: Color(0xFF151524),
    shadowLight: Color(0xFF363650),
    accent: Color(0xFFFFFFFF),
    textPrimary: Color(0xFFE0E0E0),
    textSecondary: Color(0xFF8A8A9A),
    iconDim: Color(0xFF5A5A6E),
  );

  // ── Light palette ──
  static const light = AppColors(
    background: Color(0xFFE8E8F0),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFF0F0F8),
    shadowDark: Color(0xFFC0C0D0),
    shadowLight: Color(0xFFFFFFFF),
    accent: Color(0xFF1E1E2E),
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF6A6A7E),
    iconDim: Color(0xFF9A9AAE),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceLight,
    Color? shadowDark,
    Color? shadowLight,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? iconDim,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceLight: surfaceLight ?? this.surfaceLight,
      shadowDark: shadowDark ?? this.shadowDark,
      shadowLight: shadowLight ?? this.shadowLight,
      accent: accent ?? this.accent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      iconDim: iconDim ?? this.iconDim,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      shadowDark: Color.lerp(shadowDark, other.shadowDark, t)!,
      shadowLight: Color.lerp(shadowLight, other.shadowLight, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      iconDim: Color.lerp(iconDim, other.iconDim, t)!,
    );
  }
}

/// Quick access: `context.colors.background`, etc.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

// ─── Legacy static refs (used by always-dark screens) ──────────
class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF1E1E2E);
  static const Color surface = Color(0xFF2A2A3C);
  static const Color surfaceLight = Color(0xFF323246);
  static const Color shadowDark = Color(0xFF151524);
  static const Color shadowLight = Color(0xFF363650);
  static const Color accent = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF8A8A9A);
  static const Color iconDim = Color(0xFF5A5A6E);

  static const Color primary = accent;
  static const Color card = surface;

  static ThemeData get darkTheme => _buildTheme(AppColors.dark, Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(AppColors.light, Brightness.light);

  static ThemeData _buildTheme(AppColors c, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.background,
      fontFamily: 'SF Pro Display',
      extensions: [c],
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: c.accent,
              secondary: c.accent,
              surface: c.surface,
            )
          : ColorScheme.light(
              primary: c.accent,
              secondary: c.accent,
              surface: c.surface,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: IconThemeData(color: c.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.background,
        selectedItemColor: c.accent,
        unselectedItemColor: c.iconDim,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.accent,
        inactiveTrackColor: c.surfaceLight.withValues(alpha: 0.3),
        thumbColor: c.accent,
        overlayColor: c.accent.withValues(alpha: 0.15),
        trackHeight: 3,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.accent,
        labelStyle: TextStyle(color: c.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: c.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: c.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: c.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: c.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: c.textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: c.textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: c.textSecondary, fontSize: 12),
      ),
    );
  }
}
