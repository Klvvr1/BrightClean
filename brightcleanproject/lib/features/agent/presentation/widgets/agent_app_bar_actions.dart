import 'package:flutter/material.dart';
import 'package:brightcleanproject/core/theme/app_colors.dart';
import 'package:brightcleanproject/core/controllers/language_controller.dart';
import 'package:brightcleanproject/core/controllers/theme_controller.dart';
import 'package:brightcleanproject/features/customer/data/providers/notification_provider.dart';
import 'package:provider/provider.dart';

class AgentAppBarActions extends StatelessWidget {
  final bool? isLaundryOpen;
  final ValueChanged<bool>? onAvailabilityChanged;
  final VoidCallback? onSettingsPressed;

  const AgentAppBarActions({
    super.key,
    this.isLaundryOpen,
    this.onAvailabilityChanged,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = LanguageController().isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLaundryOpen != null)
          Row(
            children: [
              Text(
                isLaundryOpen! 
                    ? (isArabic ? 'مفتوح' : 'Open') 
                    : (isArabic ? 'مغلق' : 'Closed'),
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold,
                  color: isLaundryOpen! ? AppColors.success : AppColors.error,
                ),
              ),
              Switch(
                value: isLaundryOpen!,
                onChanged: onAvailabilityChanged,
                activeThumbColor: AppColors.success,
              ),
            ],
          ),
        IconButton(
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          tooltip: isDark ? "Switch to light theme" : "Switch to dark theme",
          onPressed: () {
            ThemeController().toggleTheme();
          },
        ),
        Consumer<NotificationProvider>(
          builder: (context, notifProvider, child) => Badge(
            label: Text(notifProvider.unreadCount.toString()),
            isLabelVisible: notifProvider.unreadCount > 0,
            backgroundColor: AppColors.error,
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
          ),
        ),
        if (onSettingsPressed != null)
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: onSettingsPressed,
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}
