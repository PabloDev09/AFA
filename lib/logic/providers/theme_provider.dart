import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier 
{
  bool _isDarkMode = false; 

  bool get isDarkMode => _isDarkMode;

  // Método para alternar entre claro y oscuro
  void toggleTheme() 
  {
    _isDarkMode = !_isDarkMode;
    notifyListeners();  // Notifica a los oyentes que el tema ha cambiado
  }
}
