import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'controllers/language_controller.dart'; // غيّر المسار إذا كان مختلف عندك

void main() {
  // Initialize FFI database factory for desktop platforms (Windows, macOS, Linux)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const BrightCleanApp());
}

class BrightCleanApp extends StatelessWidget {
  const BrightCleanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController().locale,
      builder: (context, locale, child) {
        return MaterialApp.router(
          title: 'BrightClean',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar', 'AE'),
            Locale('en'),
          ],
          locale: locale,
        );
      },
    );
  }
}
