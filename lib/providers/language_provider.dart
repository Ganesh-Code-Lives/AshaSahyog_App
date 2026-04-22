import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _langCode = 'en';

  String get langCode => _langCode;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _langCode = prefs.getString('app_language') ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_langCode != code) {
      _langCode = code;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', code);
      notifyListeners();
    }
  }

  /// Helper to return the correct localized string based on the current language
  String t(String en, String hi, String mr) {
    switch (_langCode) {
      case 'hi':
        return hi;
      case 'mr':
        return mr;
      case 'en':
      default:
        return en;
    }
  }
}
