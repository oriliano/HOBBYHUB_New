// lib/providers/locale_provider.dart
import 'package:flutter/material.dart';

class LocaleProvider with ChangeNotifier {
  // Varsayılan dil Türkçe
  Locale _locale = Locale('tr');

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  void setLocale(Locale locale) {
    if (!['tr', 'en'].contains(locale.languageCode)) return;
    _locale = locale;
    notifyListeners();
  }

  // Örneğin, kolay kullanımı için yardımcı metotlar:
  void setTurkish() {
    setLocale(Locale('tr'));
  }

  void setEnglish() {
    setLocale(Locale('en'));
  }
}
