import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeMode {
  system,
  light,
  dark,
}

class ThemeManager {
  static const String THEME_KEY = 'theme_mode';

  SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.system;

  ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs?.getString(THEME_KEY);

    if (saved != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == saved,
        orElse: () => ThemeMode.system,
      );
    } else {
      _themeMode = ThemeMode.system;
    }

    themeNotifier.value = _themeMode;
    print('[ThemeManager] Initialized with mode: $_themeMode');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    themeNotifier.value = mode;
    await _prefs?.setString(THEME_KEY, mode.toString());
    print('[ThemeManager] Theme changed to: $mode');
  }

  ThemeMode get currentMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(
        navigatorKey.currentContext ?? _getDummyContext(),
      ) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  BuildContext _getDummyContext() {
    return navigatorKey.currentContext ?? _createDummyContext();
  }

  BuildContext _createDummyContext() {
    return MediaQuery(
      data: const MediaQueryData(),
      child: Container(),
    ).createState()?.context ??
    Container().createElement().getClosestAncestorStateOfType();
  }

  ThemeData getLightTheme(Color seedColor) {
    return ThemeData(
      colorSchemeSeed: seedColor,
      brightness: Brightness.light,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  ThemeData getDarkTheme(Color seedColor) {
    return ThemeData(
      colorSchemeSeed: seedColor,
      brightness: Brightness.dark,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: seedColor.withOpacity(0.8),
        foregroundColor: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
    );
  }

  ThemeData getTheme(Color seedColor, {bool? forceDark}) {
    final isDark = forceDark ?? isDarkMode;
    return isDark ? getDarkTheme(seedColor) : getLightTheme(seedColor);
  }
}
