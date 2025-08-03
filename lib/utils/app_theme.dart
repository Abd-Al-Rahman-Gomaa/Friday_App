import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF121212), // Typical dark background
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFC6B8F4), // Same seed as light theme
    brightness: Brightness.dark,
    primary: const Color(
      0xFFBCAAF4,
    ), // Slightly brighter for dark mode contrast
    secondary: const Color(0xFFD0B8A8), // Keep for consistency
    surface: const Color(0xFF1E1B2E), // Dark variant of light surface
    onPrimary: Colors.black, // Dark text/icons on bright primary
  ),
  fontFamily: 'BodoniModa',
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 50,
      color: Color.fromARGB(255, 108, 98, 157), // Pure white for contrast
    ),
    bodyMedium: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 28,
      color: Color(0xFFF6F6F6),
    ),
    bodySmall: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 20,
      color: Color(0xFFE6E1F9),
    ),
  ),
  iconTheme: const IconThemeData(color: Color.fromARGB(255, 1, 1, 1)),
  cardColor: const Color(0x885E548E), // Transparent muted violet
);
