import 'package:flutter/material.dart';

ThemeData darkTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0F172A),
  colorScheme: const ColorScheme.dark(
    primary:       Color(0xFF3B82F6),  // Blue 500 — accent
    onPrimary:     Color(0xFFFFFFFF),
    secondary:     Color(0xFF334155),  // Slate 700
    onSecondary:   Color(0xFFFFFFFF),
    surface:       Color(0xFF1E293B),  // Slate 800 — cards
    onSurface:     Color(0xFFFFFFFF),
    error:         Color(0xFFEF4444),  // Red 500 — destructive
    onError:       Color(0xFFFFFFFF),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF1E293B),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  textTheme: const TextTheme(
    // Fare display — the most important number on screen
    displayLarge:  TextStyle(fontSize: 56, fontWeight: FontWeight.w700, height: 1.1),
    // KM / Time secondary metric
    displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, height: 1.2),
    // Section headers
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    // Body text
    bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    // Labels, captions
    labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w500, 
                             color: Color(0xFF94A3B8)),
  ),
  fontFamily: 'Inter',
);

ThemeData lightTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF8FAFC),
  colorScheme: const ColorScheme.light(
    primary:       Color(0xFF3B82F6),  // Blue 500 — accent
    onPrimary:     Color(0xFFFFFFFF),
    secondary:     Color(0xFF94A3B8),  // Slate 400
    onSecondary:   Color(0xFFFFFFFF),
    surface:       Color(0xFFFFFFFF),  // White — cards
    onSurface:     Color(0xFF0F172A),
    error:         Color(0xFFEF4444),  // Red 500 — destructive
    onError:       Color(0xFFFFFFFF),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFFFFFFFF),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  textTheme: const TextTheme(
    displayLarge:  TextStyle(fontSize: 56, fontWeight: FontWeight.w700, height: 1.1, color: Color(0xFF0F172A)),
    displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, height: 1.2, color: Color(0xFF0F172A)),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
    bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF1E293B)),
    labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
  ),
  fontFamily: 'Inter',
);
