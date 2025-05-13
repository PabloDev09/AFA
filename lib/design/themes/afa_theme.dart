import 'package:flutter/material.dart';

class AfaTheme 
{
  static const Color _customColor = Color(0xFF49149F);
  static const Color _darkBackgroundColor = Color(0xFF121212);
  static const Color _lightBackgroundColor = Colors.white;

  static final List<Color> _colorThemes = 
  [
    _customColor,
    Colors.blue,
  ];

  static ThemeData lightTheme(Color primaryColor) 
  {
    return ThemeData(
      fontFamily: 'Montserrat',
      useMaterial3: true,
      colorSchemeSeed: primaryColor,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Colors.black87),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
    );
  }

  static ThemeData darkTheme(Color primaryColor) 
  {
    return ThemeData(
      fontFamily: 'Montserrat',
      useMaterial3: true,
      colorSchemeSeed: primaryColor,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: _customColor,
        textTheme: ButtonTextTheme.primary,
      ),
    );
  }

  static ThemeData theme(bool isDarkMode, int selectedColor) 
  {
    assert(
      selectedColor >= 0 && selectedColor < _colorThemes.length,
      "color index must be between 0 and ${_colorThemes.length - 1}",
    );

    return isDarkMode
        ? darkTheme(_colorThemes[selectedColor])
        : lightTheme(_colorThemes[selectedColor]);
  }
}
