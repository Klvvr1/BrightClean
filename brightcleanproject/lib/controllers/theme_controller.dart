import 'package:flutter/material.dart';

class ThemeController {
  static final ThemeController _instance = ThemeController._internal();

  factory ThemeController() {
    return _instance;
  }

  ThemeController._internal();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

  void toggleTheme() {
    if (themeMode.value == ThemeMode.dark) {
      themeMode.value = ThemeMode.light;
    } else if (themeMode.value == ThemeMode.light) {
      themeMode.value = ThemeMode.dark;
    } else {
      // If system, switch to the opposite of current brightness, but we can't easily read context here,
      // so let's default to dark if toggling from system
      themeMode.value = ThemeMode.dark;
    }
  }
  
  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
  }
}
