import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_spacing.dart';
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

  Widget _buildAvatarContent(BuildContext context) {
    final theme = Theme.of(context);
    
    if (user.imagePath == null || user.imagePath!.isEmpty) {
      return Container(
        color: theme.colorScheme.primaryContainer,
        child: Center(
          child: Icon(Icons.person, size: 50, color: theme.colorScheme.onPrimaryContainer),
        ),
      );
    }

    final file = File(user.imagePath!);
    if (!file.existsSync()) {
      return Container(
        color: theme.colorScheme.primaryContainer,
        child: Center(
          child: Icon(Icons.person, size: 50, color: theme.colorScheme.onPrimaryContainer),
        ),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: theme.colorScheme.primaryContainer,
          child: Center(
            child: Icon(Icons.person, size: 50, color: theme.colorScheme.onPrimaryContainer),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            ClipOval(
              child: SizedBox(
                width: 100,
                height: 100,
                child: _buildAvatarContent(context),
              ),
            ),
            if (isEditMode)
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.camera_alt, size: 18, color: theme.colorScheme.onPrimary),
                  onPressed: onEditAvatarPressed,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          user.name,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          user.phone,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
