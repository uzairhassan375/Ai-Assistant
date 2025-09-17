import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF121212); // Royal Blue
  static const Color primaryDark = Color(0xFF3A0CA3); // Dark Blue
  static const Color primaryLight = Color(0xFF4895EF); // Light Blue

  // Secondary colors
  static const Color secondary = Color(0xFF4CC9F0); // Sky Blue
  static const Color accent = Color(0xFFF72585); // Vibrant Pink

  // Neutral colors
  static const Color black = Color(0xFF121212);
  static const Color darkGray = Color(0xFF424242);
  static const Color mediumGray = Color(0xFF757575);
  static const Color lightGray = Color(0xFFBDBDBD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFAFAFA);

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
}

final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2196F3),
    brightness: Brightness.light,
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.black87,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
);

// Dark Theme using ColorScheme.fromSeed
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ).copyWith(
    secondary: AppColors.accent,
    error: AppColors.error,
    primaryContainer: const Color(0xFFBB86FC),
    onPrimaryContainer: Colors.black,
    secondaryContainer: const Color(0xFF03DAC6),
    onSecondaryContainer: Colors.black,
  ),
  appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
);

// Adaptive theme that responds to system settings
ThemeData getAdaptiveTheme(BuildContext context) {
  return MediaQuery.of(context).platformBrightness == Brightness.dark
      ? darkTheme
      : lightTheme;
}
