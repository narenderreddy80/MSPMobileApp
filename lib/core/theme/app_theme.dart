import 'package:flutter/material.dart';

class AppTheme {
  // Primary — rich agricultural green
  static const Color primary      = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark  = Color(0xFF1B5E20);

  // Secondary — warm harvest orange
  static const Color secondary      = Color(0xFFE65100);
  static const Color secondaryLight = Color(0xFFFF6D00);
  static const Color secondaryDark  = Color(0xFFBF360C);

  // Surfaces
  static const Color background = Color(0xFFF9F6F0);   // warm off-white
  static const Color surface    = Colors.white;
  static const Color cardTint   = Color(0xFFFFF8F0);   // faint orange-tinted card

  static const Color error      = Color(0xFFD32F2F);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary:         primary,
      onPrimary:       Colors.white,
      primaryContainer: const Color(0xFFC8E6C9),   // light green
      onPrimaryContainer: primaryDark,
      secondary:       secondary,
      onSecondary:     Colors.white,
      secondaryContainer: const Color(0xFFFFCCBC), // light orange
      onSecondaryContainer: secondaryDark,
      surface:         surface,
      onSurface:       const Color(0xFF1C1B1F),
      error:           error,
      onError:         Colors.white,
      surfaceContainerHighest: const Color(0xFFEDE7DF),
    ),

    // App bar — dark green with orange accent line
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black26,
    ),

    // Bottom nav — white with green selected
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: primary.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 11);
        }
        return TextStyle(color: Colors.grey[600], fontSize: 11);
      }),
    ),

    // Elevated buttons — orange primary action
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    ),

    // Outlined buttons — green border
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(0, 44),
      ),
    ),

    // Text buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: secondary),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: const Color(0xFFF1F8E9),  // very light green fill
    ),

    // Cards
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: surface,
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF1F8E9),
      selectedColor: primary.withValues(alpha: 0.18),
      labelStyle: const TextStyle(fontSize: 12),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // Floating action button — orange
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: secondary,
      foregroundColor: Colors.white,
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 0.8,
    ),

    // Progress indicators — green
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primary,
    ),

    fontFamily: 'Roboto',
    scaffoldBackgroundColor: background,
  );
}
