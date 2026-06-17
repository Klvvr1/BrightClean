import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_styles.dart';
import 'app_design_log.dart';

class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool shadow;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.shadow = false,
  });

  @override
  Widget build(BuildContext context) {
    AppDesignLog.widgetBuilt('AppSurfaceCard');
    final baseDecoration = AppStyles.surface(context);
    final decoration = baseDecoration.copyWith(
      color: backgroundColor ?? baseDecoration.color,
      border: borderColor == null
          ? baseDecoration.border
          : Border.all(color: borderColor!, width: 1),
      boxShadow: shadow ? AppShadows.getSm(context) : null,
    );

    final card = Container(
      margin: margin,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.card,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: AppRadius.card,
      child: card,
    );
  }
}
