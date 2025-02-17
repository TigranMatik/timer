import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme_config.dart';
import 'pro_service.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'selected_theme_id';
  final SharedPreferences _prefs;
  final ProService _proService;
  late FlowTheme _currentTheme;

  ThemeService(this._prefs, this._proService) {
    _loadTheme();
  }

  FlowTheme get currentTheme => _currentTheme;
  ThemeData get themeData => _currentTheme.themeData;
  Color get primaryColor => _currentTheme.primaryColor;
  Color get accentColor => _currentTheme.accentColor;
  Gradient get backgroundGradient => _currentTheme.backgroundGradient;
  Color get cardColor => _currentTheme.cardColor;
  Color get textColor => _currentTheme.textColor;
  IconThemeData get iconTheme => _currentTheme.iconTheme;

  void _loadTheme() {
    final themeId = _prefs.getString(_themeKey);
    if (themeId != null) {
      final theme = ThemeConfig.getThemeById(themeId);
      if (!theme.isPro || _proService.isPro) {
        _currentTheme = theme;
        return;
      }
    }
    _currentTheme = ThemeConfig.defaultTheme;
  }

  Future<void> setTheme(FlowTheme theme) async {
    if (theme.isPro && !_proService.isPro) {
      return; // Cannot set pro theme without pro subscription
    }
    
    _currentTheme = theme;
    await _prefs.setString(_themeKey, theme.id);
    notifyListeners();
  }

  Future<void> resetToDefault() async {
    _currentTheme = ThemeConfig.defaultTheme;
    await _prefs.remove(_themeKey);
    notifyListeners();
  }

  List<FlowTheme> getAvailableThemes() {
    if (_proService.isPro) {
      return ThemeConfig.allThemes;
    }
    return [ThemeConfig.defaultTheme];
  }

  Map<String, List<FlowTheme>> getThemesByCollection() {
    if (_proService.isPro) {
      return ThemeConfig.themesByCollection;
    }
    return {};
  }
} 