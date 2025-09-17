import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  double _fontScale = 1.0;

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;

  SettingsService() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];
    _fontScale = prefs.getDouble('fontScale') ?? 1.0;
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null || newThemeMode == _themeMode) return;
    _themeMode = newThemeMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('themeMode', _themeMode.index);
  }

  Future<void> updateFontScale(double newScale) async {
    if (newScale == _fontScale) return;
    _fontScale = newScale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('fontScale', newScale);
  }
}
