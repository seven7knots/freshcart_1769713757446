import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  static const String _hasChosenLanguageKey = 'has_chosen_language';

  Locale _locale = const Locale('en');
  bool _hasChosenLanguage = false;
  bool _isInitialized = false;

  Locale get locale => _locale;
  bool get hasChosenLanguage => _hasChosenLanguage;
  bool get isInitialized => _isInitialized;
  bool get isArabic => _locale.languageCode == 'ar';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);
    _hasChosenLanguage = prefs.getBool(_hasChosenLanguageKey) ?? false;

    if (savedLocale != null) {
      _locale = Locale(savedLocale);
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    final changed = _locale != locale;
    _locale = locale;
    _hasChosenLanguage = true;
    if (changed) notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    await prefs.setBool(_hasChosenLanguageKey, true);
  }

  Future<void> markLanguageChosen() async {
    _hasChosenLanguage = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasChosenLanguageKey, true);
  }
}
