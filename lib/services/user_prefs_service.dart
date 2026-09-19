// lib/services/user_prefs_service.dart
//
// Wraps SharedPreferences to persist the two things that aren't real
// "tasks": the user's profile info and their light/dark theme choice.
// SharedPreferences is the right tool here (small primitive values),
// while Hive handles the actual task objects — a good example of using
// each storage tool for what it's best at.

import 'package:shared_preferences/shared_preferences.dart';

class UserPrefsService {
  static const _keyName = 'user_name';
  static const _keyRole = 'user_role';
  static const _keyThemeMode = 'theme_mode'; // 'light' | 'dark'

  Future<String> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName) ?? 'User';
  }

  Future<void> setName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
  }

  Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole) ?? 'enter your role';
  }

  Future<void> setRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, role);
  }

  Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) == 'dark';
  }

  Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, isDark ? 'dark' : 'light');
  }
}
