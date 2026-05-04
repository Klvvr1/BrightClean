import 'package:flutter/material.dart';

class LanguageController {
  // Singleton pattern to ensure only one instance exists
  static final LanguageController _instance = LanguageController._internal();

  factory LanguageController() {
    return _instance;
  }

  LanguageController._internal();

  // ValueNotifier to hold the current locale and notify listeners of changes
  final ValueNotifier<Locale> locale = ValueNotifier<Locale>(const Locale('ar', 'AE'));

  bool get isArabic => locale.value.languageCode == 'ar';

  // Method to change the language
  void changeLanguage(Locale newLocale) {
    locale.value = newLocale;
  }

  void toggleLanguage() {
    locale.value = locale.value.languageCode == 'ar' 
        ? const Locale('en') 
        : const Locale('ar', 'AE');
  }
}
