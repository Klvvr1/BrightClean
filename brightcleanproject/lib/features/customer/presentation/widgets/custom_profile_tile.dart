import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

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
    final Color itemColor = isDestructive
        ? AppColors.error
        : (Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textMain);

    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.primary,
      ),
      title: Text(
        title,
        style: TextStyle(color: itemColor, fontWeight: FontWeight.w500),
      ),
      trailing: trailing ??
          (isDestructive
              ? null
              : const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey)),
      onTap: onTap,
    );
  }
}
