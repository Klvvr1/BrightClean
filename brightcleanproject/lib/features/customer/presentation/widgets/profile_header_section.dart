import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../models/user_profile.dart';

class ProfileHeaderSection extends StatelessWidget {
  final UserProfile user;
  final bool isEditMode;
  final VoidCallback? onEditAvatarPressed;

  const ProfileHeaderSection({
    super.key,
    required this.user,
    required this.isEditMode,
    this.onEditAvatarPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.lightBlue,
              backgroundImage:
                  (user.imagePath != null && user.imagePath!.isNotEmpty)
                      ? FileImage(File(user.imagePath!))
                      : null,
              child: (user.imagePath == null || user.imagePath!.isEmpty)
                  ? const Icon(Icons.person, size: 50, color: AppColors.white)
                  : null,
            ),
            if (isEditMode)
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt,
                      size: 18, color: AppColors.white),
                  onPressed: onEditAvatarPressed,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          user.phone,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : AppColors.textLight,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
