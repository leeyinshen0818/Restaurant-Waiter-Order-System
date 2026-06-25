import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color primaryTerracotta = Color(0xFFB85C38);
  static const Color darkTerracotta = Color(0xFF8F3F24);
  static const Color backgroundCream = Color(0xFFFFF9F3);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color mainText = Color(0xFF2D2A26);
  static const Color secondaryText = Color(0xFF756F68);
  static const Color border = Color(0xFFE8DED5);
  static const Color error = Color(0xFFC94C4C);

  static final ColorScheme _colorScheme =
      ColorScheme.fromSeed(
        seedColor: primaryTerracotta,
        brightness: Brightness.light,
      ).copyWith(
        primary: primaryTerracotta,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFF6DED3),
        onPrimaryContainer: darkTerracotta,
        secondary: darkTerracotta,
        onSecondary: Colors.white,
        surface: cardBackground,
        onSurface: mainText,
        outline: border,
        error: error,
        onError: Colors.white,
      );

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: backgroundCream,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundCream,
      foregroundColor: mainText,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: mainText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardBackground,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cardBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titleTextStyle: const TextStyle(
        color: mainText,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: const TextStyle(
        color: mainText,
        fontSize: 15,
        height: 1.35,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryTerracotta,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryTerracotta,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkTerracotta,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: cardBackground,
      selectedColor: primaryTerracotta,
      side: const BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: const TextStyle(
        color: mainText,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      checkmarkColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: cardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: secondaryText),
      labelStyle: const TextStyle(color: secondaryText),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryTerracotta, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: error, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      height: 68,
      indicatorColor: const Color(0xFFF6DED3),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? darkTerracotta
              : secondaryText,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? darkTerracotta
              : secondaryText,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryTerracotta,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: StadiumBorder(),
      extendedTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: mainText,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? primaryTerracotta
            : secondaryText,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? primaryTerracotta.withValues(alpha: 0.28)
            : border,
      ),
    ),
    dividerTheme: const DividerThemeData(color: border, space: 1),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: mainText,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        color: mainText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: mainText,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: TextStyle(
        color: mainText,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(color: mainText, fontSize: 16),
      bodyMedium: TextStyle(color: secondaryText, fontSize: 14),
      bodySmall: TextStyle(color: secondaryText, fontSize: 12),
    ),
  );
}
