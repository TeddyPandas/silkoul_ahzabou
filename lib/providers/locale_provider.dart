import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';

  Locale _locale = const Locale('fr'); // Français par défaut

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  /// Charge la langue sauvegardée depuis SharedPreferences
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(_localeKey) ?? 'fr';
    _locale = Locale(langCode);
    notifyListeners();
  }

  /// Change la langue et la sauvegarde
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }

  /// Bascule entre FR et EN
  Future<void> toggleLocale() async {
    final newLocale = _locale.languageCode == 'fr'
        ? const Locale('en')
        : const Locale('fr');
    await setLocale(newLocale);
  }

  /// Retourne le nom lisible de la langue actuelle
  String get currentLanguageName =>
      _locale.languageCode == 'fr' ? 'Français' : 'English';

  /// Retourne le drapeau emoji de la langue actuelle
  String get currentFlag =>
      _locale.languageCode == 'fr' ? '🇫🇷' : '🇬🇧';
}
