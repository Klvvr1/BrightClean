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

  Widget _buildAvatarContent() {
    if (user.imagePath == null || user.imagePath!.isEmpty) {
      return Container(
        color: AppColors.lightBlue,
        child: const Center(
          child: Icon(Icons.person, size: 50, color: AppColors.white),
        ),
      );
    }

    final file = File(user.imagePath!);
    if (!file.existsSync()) {
      return Container(
        color: AppColors.lightBlue,
        child: const Center(
          child: Icon(Icons.person, size: 50, color: AppColors.white),
        ),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppColors.lightBlue,
          child: const Center(
            child: Icon(Icons.person, size: 50, color: AppColors.white),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            ClipOval(
              child: SizedBox(
                width: 100,
                height: 100,
                child: _buildAvatarContent(),
              ),
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
