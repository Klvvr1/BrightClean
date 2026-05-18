import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/language_controller.dart';

class AppTextStyles {
  AppTextStyles._();

  /// Retrieves the typography mapped perfectly to Material 3 standard hierarchy.
  /// Automatically applies Cairo for Arabic ('ar') and Inter for English ('en').
  static TextTheme getTextTheme(BuildContext context, {Brightness brightness = Brightness.light}) {
    // Get the current locale string (defaults to 'ar' if not found or system default)
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? LanguageController().locale.value.languageCode;
    
    final baseTheme = brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final fontFunction = locale == 'en' ? GoogleFonts.interTextTheme : GoogleFonts.cairoTextTheme;

    // Apply the language-specific font to the base text theme
    return fontFunction(baseTheme).copyWith(
      displayLarge: fontFunction(baseTheme).displayLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 57),
      displayMedium: fontFunction(baseTheme).displayMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 45),
      displaySmall: fontFunction(baseTheme).displaySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 36),
      
      headlineLarge: fontFunction(baseTheme).headlineLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 32),
      headlineMedium: fontFunction(baseTheme).headlineMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 28),
      headlineSmall: fontFunction(baseTheme).headlineSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 24),
      
      titleLarge: fontFunction(baseTheme).titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 22),
      titleMedium: fontFunction(baseTheme).titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
      titleSmall: fontFunction(baseTheme).titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
      
      bodyLarge: fontFunction(baseTheme).bodyLarge?.copyWith(fontWeight: FontWeight.normal, fontSize: 16),
      bodyMedium: fontFunction(baseTheme).bodyMedium?.copyWith(fontWeight: FontWeight.normal, fontSize: 14),
      bodySmall: fontFunction(baseTheme).bodySmall?.copyWith(fontWeight: FontWeight.normal, fontSize: 12),
      
      labelLarge: fontFunction(baseTheme).labelLarge?.copyWith(fontWeight: FontWeight.w500, fontSize: 14),
      labelMedium: fontFunction(baseTheme).labelMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: 12),
      labelSmall: fontFunction(baseTheme).labelSmall?.copyWith(fontWeight: FontWeight.w500, fontSize: 11),
    );
  }
}
