import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_radius.dart';

/// Reusable stylistic decorators and components (e.g., Glassmorphism)
class AppStyles {
  AppStyles._();

  /// A modern, soft glassmorphism container style.
  /// NOTE: This uses BackdropFilter which can be performance heavy.
  /// Use strictly as an accent for floating cards, modals, or premium highlights.
  static Widget glassContainer({
    required Widget child,
    required BuildContext context,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    double blur = 10.0,
    double opacity = 0.15,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.white; // Usually white or light tint works best for glass

    return ClipRRect(
      borderRadius: borderRadius ?? AppRadius.card,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: opacity),
            borderRadius: borderRadius ?? AppRadius.card,
            border: Border.all(
              color: baseColor.withValues(alpha: isDark ? 0.1 : 0.2),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  /// A standard surface container decoration inheriting from the theme
  static BoxDecoration surface(BuildContext context, {BorderRadius? borderRadius}) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: borderRadius ?? AppRadius.card,
      border: Border.all(
        color: theme.brightness == Brightness.dark
            ? Colors.white12
            : Colors.grey.shade200,
        width: 1,
      ),
    );
  }
}
