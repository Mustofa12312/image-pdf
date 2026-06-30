import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class SettingsController extends ChangeNotifier {
  late SharedPreferences _prefs;

  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'id';
  int _defaultDpi = AppConstants.defaultDpi;
  int _defaultQuality = AppConstants.defaultQuality;
  bool _rememberFolder = true;
  String? _lastFolder;

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  int get defaultDpi => _defaultDpi;
  int get defaultQuality => _defaultQuality;
  bool get rememberFolder => _rememberFolder;
  String? get lastFolder => _lastFolder;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _themeMode = _prefs.getString(AppConstants.prefTheme) == 'light'
        ? ThemeMode.light
        : ThemeMode.dark;
    _language = _prefs.getString(AppConstants.prefLanguage) ?? 'id';
    _defaultDpi = _prefs.getInt(AppConstants.prefDefaultDpi) ?? AppConstants.defaultDpi;
    _defaultQuality = _prefs.getInt(AppConstants.prefDefaultQuality) ?? AppConstants.defaultQuality;
    _rememberFolder = _prefs.getBool(AppConstants.prefRememberFolder) ?? true;
    _lastFolder = _prefs.getString(AppConstants.prefLastFolder);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(AppConstants.prefTheme, mode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _prefs.setString(AppConstants.prefLanguage, lang);
    notifyListeners();
  }

  Future<void> setDefaultDpi(int dpi) async {
    _defaultDpi = dpi;
    await _prefs.setInt(AppConstants.prefDefaultDpi, dpi);
    notifyListeners();
  }

  Future<void> setDefaultQuality(int quality) async {
    _defaultQuality = quality;
    await _prefs.setInt(AppConstants.prefDefaultQuality, quality);
    notifyListeners();
  }

  Future<void> setRememberFolder(bool val) async {
    _rememberFolder = val;
    await _prefs.setBool(AppConstants.prefRememberFolder, val);
    notifyListeners();
  }

  Future<void> saveLastFolder(String folder) async {
    if (_rememberFolder) {
      _lastFolder = folder;
      await _prefs.setString(AppConstants.prefLastFolder, folder);
    }
  }
}
