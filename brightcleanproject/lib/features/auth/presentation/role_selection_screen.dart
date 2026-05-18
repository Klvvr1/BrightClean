import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_styles.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: AppStyles.surface(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.card,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.primary.withValues(alpha: 0.3) : AppColors.lightBlue,
                    borderRadius: AppRadius.button,
                  ),
                  child: Icon(icon, color: isDark ? Colors.white : AppColors.primary, size: 32),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                          color: isDark ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر نوع الحساب'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'الرجاء اختيار نوع الحساب الذي ترغب في تسجيله',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildRoleCard(
              context: context,
              title: 'عميل (Customer)',
              icon: Icons.person_outline,
              onTap: () => context.push('/register/customer'),
            ),
            _buildRoleCard(
              context: context,
              title: 'مغسلة (Laundry Agent)',
              icon: Icons.local_laundry_service_outlined,
              onTap: () => context.push('/register/agent'),
            ),
            _buildRoleCard(
              context: context,
              title: 'سائق (Delivery Driver)',
              icon: Icons.drive_eta_outlined,
              onTap: () => context.push('/register/driver'),
            ),
          ],
        ),
      ),
    );
  }
}
