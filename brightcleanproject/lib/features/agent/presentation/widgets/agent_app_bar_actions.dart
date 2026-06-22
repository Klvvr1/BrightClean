import 'package:flutter/material.dart';
import 'package:brightcleanproject/core/theme/app_colors.dart';
import 'package:brightcleanproject/core/controllers/language_controller.dart';

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
