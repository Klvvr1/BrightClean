import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.water_drop,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'تسجيل الدخول',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'مرحباً بك مجدداً في برايت كلين',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textLight,
                      ),
                ),
                const SizedBox(height: 48),
                const CustomTextField(
                  hintText: 'رقم الهاتف',
                  prefixIcon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                const CustomTextField(
                  hintText: 'كلمة المرور',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Note: Implement actual login logic based on role when backend is ready
                    // For now, let's route to Customer Home as default
                    context.go('/customer_home');
                  },
                  child: const Text('دخول'),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('ليس لديك حساب؟', style: TextStyle(color: AppColors.textMain)),
                    TextButton(
                      onPressed: () {
                        context.push('/role_selection');
                      },
                      child: const Text('تسجيل جديد'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'تسجيل دخول سريع (للاختبار):',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.go('/admin'),
                      icon: const Icon(Icons.admin_panel_settings, size: 16),
                      label: const Text('مشرف'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/customer_home'),
                      icon: const Icon(Icons.person, size: 16),
                      label: const Text('عميل'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/driver_dashboard'),
                      icon: const Icon(Icons.drive_eta, size: 16),
                      label: const Text('سائق'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/agent_dashboard'),
                      icon: const Icon(Icons.local_laundry_service, size: 16),
                      label: const Text('مغسلة'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
