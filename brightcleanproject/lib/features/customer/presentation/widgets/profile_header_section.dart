import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../models/user_profile.dart';

class ProfileHeaderSection extends StatelessWidget {
  final UserProfile user;
  final bool isEditMode;

  const ProfileHeaderSection({
    super.key,
    required this.user,
    required this.isEditMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.lightBlue,
              child: Icon(Icons.person, size: 50, color: AppColors.white),
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
                  onPressed: () {
                    // منطق تغيير الصورة
                  },
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
          style: const TextStyle(color: AppColors.textLight, fontSize: 16),
        ),
      ],
    );
  }
}
