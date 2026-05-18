import 'package:flutter/material.dart';

class CustomProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  final Widget? trailing;

  const CustomProfileTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color itemColor = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? theme.colorScheme.error : theme.colorScheme.primary,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(color: itemColor, fontWeight: FontWeight.w500),
      ),
      trailing: trailing ??
          (isDestructive
              ? null
              : Icon(Icons.arrow_forward_ios,
                  size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
      onTap: onTap,
    );
  }
}
