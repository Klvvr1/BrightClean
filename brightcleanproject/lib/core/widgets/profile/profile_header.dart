import 'dart:io';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String? imagePath;
  final bool isEditMode;
  final VoidCallback? onEditAvatarPressed;
  final Widget? statusBadge;

  const ProfileHeader({
    super.key,
    required this.name,
    this.subtitle,
    this.imagePath,
    this.isEditMode = false,
    this.onEditAvatarPressed,
    this.statusBadge,
  });

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
            if (statusBadge != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: statusBadge!,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatarContent(BuildContext context) {
    final theme = Theme.of(context);

    if (imagePath == null || imagePath!.isEmpty) {
      return Container(
        color: theme.colorScheme.primaryContainer,
        child: Center(
          child: Icon(Icons.person, size: 50, color: theme.colorScheme.onPrimaryContainer),
        ),
      );
    }

    final file = File(imagePath!);
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
}
