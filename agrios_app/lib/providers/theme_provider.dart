import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    // Light mode is locked on for the mobile app.
    if (_isDarkMode) {
      _isDarkMode = false;
      notifyListeners();
    }
  }
}













