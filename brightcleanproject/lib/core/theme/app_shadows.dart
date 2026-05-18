import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  static List<BoxShadow> lightSm = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> lightMd = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> lightLg = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> darkSm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> darkMd = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> darkLg = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // Helper method to retrieve appropriate shadow based on theme
  static List<BoxShadow> getSm(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSm : lightSm;
  }

  static List<BoxShadow> getMd(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkMd : lightMd;
  }

  static List<BoxShadow> getLg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkLg : lightLg;
  }
}
