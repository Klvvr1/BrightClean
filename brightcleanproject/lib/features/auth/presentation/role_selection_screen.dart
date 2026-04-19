import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر نوع الحساب'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'الرجاء اختيار نوع الحساب الذي ترغب في تسجيله',
              style: TextStyle(fontSize: 16, color: AppColors.textMain),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
