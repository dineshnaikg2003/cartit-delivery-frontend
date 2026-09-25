import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Follow system theme setting by default

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(BuildContext context) {
    bool isCurrentDark = Theme.of(context).brightness == Brightness.dark;
    _themeMode = isCurrentDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
