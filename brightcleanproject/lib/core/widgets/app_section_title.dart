import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_design_log.dart';

class AppSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? action;

  const AppSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    AppDesignLog.widgetBuilt('AppSectionTitle');
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: AppSpacing.sm),
          action!,
        ],
      ],
    );
  }
}
