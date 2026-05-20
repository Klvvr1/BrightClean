import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/controllers/language_controller.dart';

import 'core/controllers/theme_controller.dart';
import 'package:provider/provider.dart';
import 'features/customer/data/providers/order_provider.dart';
import 'features/customer/data/providers/review_provider.dart';
import 'features/customer/data/providers/cart_provider.dart';
import 'features/driver/data/providers/driver_provider.dart';

void main() {
  // Initialize FFI database factory for desktop platforms (Windows, macOS, Linux)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
      ],
      child: const BrightCleanApp(),
    ),
  );
}

class BrightCleanApp extends StatelessWidget {
  const BrightCleanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController().themeMode,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LanguageController().locale,
          builder: (context, locale, child) {
            return MaterialApp.router(
              title: 'BrightClean',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.getLightTheme(context),
              darkTheme: AppTheme.getDarkTheme(context),
              themeMode: themeMode,
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
      },
    );
  }
}

