import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'app_design_log.dart';
import 'app_surface_card.dart';

class AppStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final bool emphasis;

  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.accentColor = AppColors.primary,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    AppDesignLog.widgetBuilt('AppStatCard');
    if (emphasis) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor, accentColor.withValues(alpha: 0.82)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.card,
          boxShadow: AppShadows.getMd(context),
        ),
        child: _StatContent(
          title: title,
          value: value,
          subtitle: subtitle,
          icon: icon,
          accentColor: Colors.white,
          onAccentColor: Colors.white,
          emphasis: true,
        ),
      );
    }

    return AppSurfaceCard(
      child: _StatContent(
        title: title,
        value: value,
        subtitle: subtitle,
        icon: icon,
        accentColor: accentColor,
        onAccentColor: accentColor,
      ),
    );
  }
}

class _StatContent extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final Color onAccentColor;
  final bool emphasis;

  const _StatContent({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.onAccentColor,
    this.subtitle,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = emphasis ? Colors.white : theme.colorScheme.onSurface;
    final mutedColor = emphasis
        ? Colors.white.withValues(alpha: 0.78)
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: emphasis
                ? Colors.white.withValues(alpha: 0.16)
                : accentColor.withValues(alpha: 0.1),
            borderRadius: AppRadius.button,
          ),
          child: Icon(icon, color: onAccentColor, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: mutedColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style:
                      theme.textTheme.labelSmall?.copyWith(color: mutedColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
