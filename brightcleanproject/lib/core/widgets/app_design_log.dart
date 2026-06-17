import 'package:flutter/foundation.dart';

class AppDesignLog {
  AppDesignLog._();

  static const bool enabled = bool.fromEnvironment('BRIGHTCLEAN_DESIGN_LOGS');

  static void widgetBuilt(String name) {
    if (kDebugMode && enabled) {
      debugPrint('BrightClean design widget built: $name');
    }
  }
}
