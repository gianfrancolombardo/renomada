// ===========================
// UI 2 – Material 3 Theme
// Claro + Oscuro
// ===========================
import 'package:flutter/material.dart';

class UI2Theme {
  // Colores base (tu paleta)
  static const Color white     = Color(0xFFFFFFFF);
  static const Color darkGrey  = Color(0xFF313131);
  static const Color lavender  = Color(0xFF87BEFE); // Primary
  static const Color magenta   = Color(0xFFFF55DD); // Secondary
  static const Color lime      = Color(0xFFFBFF79); // Tertiary

  // -------- LIGHT SCHEME --------
  static final ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: lavender,
    onPrimary: darkGrey,
    primaryContainer: const Color(0xFFD4E7FF),
    onPrimaryContainer: darkGrey,

    secondary: magenta,
    onSecondary: darkGrey,
    secondaryContainer: const Color(0xFFFFB3F2),
    onSecondaryContainer: darkGrey,

    tertiary: lime,
    onTertiary: darkGrey,
    tertiaryContainer: const Color(0xFFFFFDB1),
    onTertiaryContainer: darkGrey,

    surface: white,
    onSurface: darkGrey,
    surfaceDim: const Color(0xFFF2F2F2),
    surfaceBright: Colors.white,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFF8F8F8),
    surfaceContainer: const Color(0xFFF3F3F3),
    surfaceContainerHigh: const Color(0xFFEEEEEE),
    surfaceContainerHighest: const Color(0xFFE9E9E9),

    background: white,
    onBackground: darkGrey,

    error: const Color(0xFFBA1A1A),
    onError: Colors.white,
    errorContainer: const Color(0xFFFFDAD6),
    onErrorContainer: const Color(0xFF410002),

    outline: const Color(0xFF9E9E9E),
    outlineVariant: const Color(0xFFE0E0E0),

    shadow: Colors.black,
    scrim: Colors.black,

    inverseSurface: darkGrey,
    onInverseSurface: white,
    inversePrimary: const Color(0xFF4B83C3),
  );

  // -------- DARK SCHEME --------
  static final ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: lavender,
    onPrimary: darkGrey,
    primaryContainer: const Color(0xFF5BA3FB),
    onPrimaryContainer: darkGrey,

    secondary: magenta,
    onSecondary: darkGrey,
    secondaryContainer: const Color(0xFFFF89EA),
    onSecondaryContainer: darkGrey,

    tertiary: lime,
    onTertiary: darkGrey,
    tertiaryContainer: const Color(0xFFEEF37A),
    onTertiaryContainer: darkGrey,

    surface: darkGrey,
    onSurface: white,
    surfaceDim: const Color(0xFF252525),
    surfaceBright: const Color(0xFF3A3A3A),
    surfaceContainerLowest: const Color(0xFF1F1F1F),
    surfaceContainerLow: const Color(0xFF2A2A2A),
    surfaceContainer: const Color(0xFF303030),
    surfaceContainerHigh: const Color(0xFF353535),
    surfaceContainerHighest: const Color(0xFF3B3B3B),

    background: darkGrey,
    onBackground: white,

    error: const Color(0xFFFFB4AB),
    onError: const Color(0xFF690005),
    errorContainer: const Color(0xFF93000A),
    onErrorContainer: const Color(0xFFFFDAD6),

    outline: const Color(0xFF8C8C8C),
    outlineVariant: const Color(0xFF444444),

    shadow: Colors.black,
    scrim: Colors.black,

    inverseSurface: white,
    onInverseSurface: darkGrey,
    inversePrimary: const Color(0xFFA4CEFF),
  );

  // -------- THEME FACTORIES --------
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        textTheme: _textTheme(darkGrey),
        appBarTheme: AppBarTheme(
          backgroundColor: lightColorScheme.surface,
          foregroundColor: lightColorScheme.onSurface,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: lightColorScheme.primary,
            foregroundColor: lightColorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: lightColorScheme.secondaryContainer,
            foregroundColor: lightColorScheme.onSecondaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        cardTheme: CardTheme(
          color: lightColorScheme.surfaceContainerHigh,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        chipTheme: ChipThemeData(
          color: MaterialStatePropertyAll(lightColorScheme.surfaceContainer),
          labelStyle: TextStyle(color: lightColorScheme.onSurface),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        textTheme: _textTheme(white),
        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.surface,
          foregroundColor: darkColorScheme.onSurface,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkColorScheme.primary,
            foregroundColor: darkColorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: darkColorScheme.secondaryContainer,
            foregroundColor: darkColorScheme.onSecondaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        cardTheme: CardTheme(
          color: darkColorScheme.surfaceContainerHigh,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        chipTheme: ChipThemeData(
          color: MaterialStatePropertyAll(darkColorScheme.surfaceContainer),
          labelStyle: TextStyle(color: darkColorScheme.onSurface),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  static TextTheme _textTheme(Color baseColor) {
    return Typography.material2021().black.apply(
          bodyColor: baseColor,
          displayColor: baseColor,
        );
  }
}

// Uso:
// MaterialApp(
//   theme: UI2Theme.light(),
//   darkTheme: UI2Theme.dark(),
//   themeMode: ThemeMode.system,
//   home: const YourHome(),
// );
