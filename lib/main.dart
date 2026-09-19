// lib/main.dart
//
// App entry point. Same Hive init sequence as before (register adapter,
// open box, before runApp). Now also loads the saved light/dark
// preference and hands theme control down to HomeScreen via a toggle
// callback, so the whole app can flip themes without a full restart.

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/task.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/user_prefs_service.dart';
import 'theme/app_theme.dart';

/// Shared box name constant so every file references the same box.
const String taskBoxName = 'tasksBox';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Task>(taskBoxName);

  // Sets up notification channels and requests permission up front, so
  // reminders "just work" the first time a user sets one.
  await NotificationService().initialize();

  runApp(const TodoApp());
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  final _prefsService = UserPrefsService();
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final isDark = await _prefsService.isDarkMode();
    if (!mounted) return;
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _toggleTheme() async {
    final goingDark = _themeMode == ThemeMode.light;
    setState(() => _themeMode = goingDark ? ThemeMode.dark : ThemeMode.light);
    await _prefsService.setDarkMode(goingDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskMaster',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: HomeScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}
