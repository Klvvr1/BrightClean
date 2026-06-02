import 'dart:io';
import 'dart:ui';
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
import 'features/auth/data/providers/auth_provider.dart';
import 'features/admin/data/providers/admin_provider.dart';
import 'features/customer/data/providers/notification_provider.dart';

void main() {
  // Initialize FFI database factory for desktop platforms (Windows, macOS, Linux)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Global Flutter framework error handler — prevents red screen crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(
        details); // MUST be called to render the fallback ErrorWidget
    debugPrint('🔴 FlutterError: ${details.exceptionAsString()}');
    debugPrint('🔴 Stack: ${details.stack}');
  };

  // Catch async errors that escape the Flutter framework (e.g. microtask failures)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔴 PlatformDispatcher error: $error');
    debugPrint('🔴 Stack: $stack');
    return true; // Prevent the app from terminating
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProxyProvider<CartProvider, OrderProvider>(
          create: (ctx) => OrderProvider(
            cartProvider: Provider.of<CartProvider>(ctx, listen: false),
          ),
          update: (ctx, cart, previous) =>
              previous ?? OrderProvider(cartProvider: cart),
        ),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
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
