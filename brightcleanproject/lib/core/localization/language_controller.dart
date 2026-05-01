import 'package:flutter/material.dart';

class LanguageController {
  static final LanguageController _instance = LanguageController._internal();
  factory LanguageController() => _instance;
  LanguageController._internal();

  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('ar'));

  bool get isArabic => locale.value.languageCode == 'ar';

  void toggleLanguage() {
    locale.value = locale.value.languageCode == 'ar' 
        ? const Locale('en') 
        : const Locale('ar');
  }
}
