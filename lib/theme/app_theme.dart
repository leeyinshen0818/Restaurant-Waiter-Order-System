import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color primaryDark = Color(0xFF1B4332);
  static const Color primaryDarkHover = Color(0xFF081C15);
  static const Color primaryTerracotta = Color(0xFFD4AF37);
  static const Color darkTerracotta = Color(0xFFB08D2C);
  static const Color softTerracotta = Color(0xFFFDF6E3);
  static const Color backgroundCream = Color(0xFFFDFBF7);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color mainText = Color(0xFF292624);
  static const Color secondaryText = Color(0xFF746E68);
  static const Color mutedText = Color(0xFF9A948E);
  static const Color border = Color(0xFFE6E0DA);
  static const Color softSurface = Color(0xFFF1EEE9);
  static const Color error = Color(0xFFB94A48);

  static final ColorScheme _colorScheme =
      ColorScheme.fromSeed(
        seedColor: primaryTerracotta,
        brightness: Brightness.light,
      ).copyWith(
        primary: primaryDark,
        onPrimary: Colors.white,
        primaryContainer: softTerracotta,
        onPrimaryContainer: darkTerracotta,
        secondary: primaryTerracotta,
        onSecondary: Colors.white,
        secondaryContainer: softTerracotta,
        onSecondaryContainer: darkTerracotta,
        surface: cardBackground,
        onSurface: mainText,
        surfaceContainerHighest: softSurface,
        onSurfaceVariant: secondaryText,
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
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
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
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: cardBackground,
        foregroundColor: primaryDark,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryTerracotta,
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
        borderSide: const BorderSide(color: primaryTerracotta, width: 1.6),
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
      elevation: 0,
      height: 68,
      indicatorColor: softTerracotta,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? primaryTerracotta
              : secondaryText,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? primaryTerracotta
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
      elevation: 2,
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
        (states) =>
            states.contains(WidgetState.selected) ? primaryDark : secondaryText,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? primaryTerracotta.withValues(alpha: 0.22)
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
