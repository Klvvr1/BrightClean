import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/widgets/profile/profile_widgets.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/controllers/theme_controller.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  String _userName = 'مدير النظام';
  String _userPhone = '0500000000';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'مدير النظام';
        _userPhone = prefs.getString('user_phone') ?? '0500000000';
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final t = Theme.of(ctx);
        return AlertDialog(
          title: Text('تسجيل الخروج', style: TextStyle(color: t.colorScheme.error)),
          content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('إلغاء', style: TextStyle(color: t.colorScheme.onSurface.withValues(alpha: 0.6))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: t.colorScheme.error, foregroundColor: t.colorScheme.onError),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_phone');
      await prefs.remove('user_role');
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ProfileHeader(
            name: _userName,
            subtitle: 'مدير النظام',
          ),
          const SizedBox(height: AppSpacing.xxl),
          _buildInfoSection(),
          const SizedBox(height: AppSpacing.md),
          _buildManagementSection(),
          const SizedBox(height: AppSpacing.md),
          _buildSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      decoration: AppStyles.surface(context),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          AccountInfoCard(
            icon: Icons.phone_outlined,
            label: 'رقم الهاتف',
            value: _userPhone,
          ),
          const Divider(height: 1),
          AccountInfoCard(
            icon: Icons.email_outlined,
            label: 'البريد الإلكتروني',
            value: 'admin@brightclean.com',
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSection() {
    return Container(
      decoration: AppStyles.surface(context),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          ProfileMenuTile(
            icon: Icons.dashboard_outlined,
            title: 'لوحة التحكم',
            onTap: () => context.go('/admin'),
          ),
          const Divider(height: 1),
          ProfileMenuTile(
            icon: Icons.people_outline,
            title: 'إدارة المستخدمين',
            onTap: () {},
          ),
          const Divider(height: 1),
          ProfileMenuTile(
            icon: Icons.cleaning_services_outlined,
            title: 'إدارة الخدمات',
            onTap: () {},
          ),
          const Divider(height: 1),
          ProfileMenuTile(
            icon: Icons.local_offer_outlined,
            title: 'العروض والكوبونات',
            onTap: () {},
          ),
          const Divider(height: 1),
          ProfileMenuTile(
            icon: Icons.bar_chart_outlined,
            title: 'التقارير والإحصائيات',
            onTap: () {},
          ),
          const Divider(height: 1),
          ProfileMenuTile(
            icon: Icons.notifications_outlined,
            title: 'الإشعارات',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: AppStyles.surface(context),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          ProfileMenuTile(
            icon: Icons.lock_outline,
            title: 'تغيير كلمة المرور',
            onTap: () {},
          ),
          const Divider(height: 1),
          ProfileMenuTile(
            icon: Icons.dark_mode,
            title: 'الوضع الليلي',
            trailing: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController().themeMode,
              builder: (context, themeMode, child) {
                final isDark = themeMode == ThemeMode.dark ||
                    (themeMode == ThemeMode.system &&
                        MediaQuery.of(context).platformBrightness == Brightness.dark);
                return Switch(
                  value: isDark,
                  onChanged: (_) => ThemeController().toggleTheme(),
                );
              },
            ),
          ),
          const Divider(height: 1),
          ProfileMenuTile(
            icon: Icons.logout,
            title: 'تسجيل الخروج',
            isDestructive: true,
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }
}
