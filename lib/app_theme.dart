import 'package:flutter/material.dart';

class AppTheme {
  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6750A4),
    brightness: Brightness.light,
  );
  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6750A4),
    brightness: Brightness.dark,
  );

  // Mantemos o tema básico para máxima compatibilidade entre versões
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _lightScheme,
        visualDensity: VisualDensity.comfortable,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: _darkScheme,
        visualDensity: VisualDensity.comfortable,
      );
}
