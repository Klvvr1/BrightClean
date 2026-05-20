import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../auth/data/providers/auth_provider.dart';
import '../../customer/data/providers/cart_provider.dart';
import '../../../../core/widgets/profile/profile_widgets.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/theme/app_colors.dart';

class AdminProfileScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  const AdminProfileScreen({super.key, this.onTabChange});

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
      await Provider.of<AuthProvider>(context, listen: false).logout(
        Provider.of<CartProvider>(context, listen: false)
      );
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
          const SizedBox(height: AppSpacing.xl),
          
          // معلومات الحساب
          _buildSettingsHeader('معلومات الحساب'),
          _buildSettingsTile(
            Icons.phone_outlined,
            'رقم الهاتف',
            subtitle: _userPhone,
          ),
          _buildSettingsTile(
            Icons.email_outlined,
            'البريد الإلكتروني',
            subtitle: 'admin@brightclean.com',
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // إدارة النظام
          _buildSettingsHeader('إدارة النظام'),
          _buildSettingsTile(
            Icons.dashboard_outlined,
            'لوحة التحكم',
            subtitle: 'إدارة طلبات وإحصائيات التطبيق',
            onTap: () {
              if (widget.onTabChange != null) {
                widget.onTabChange!(0);
              } else {
                context.go('/admin');
              }
            },
          ),
          _buildSettingsTile(
            Icons.people_outline,
            'إدارة التسجيلات والمستخدمين',
            subtitle: 'إدارة بيانات العملاء والمناديب والوكلاء والتسجيلات الجديدة',
            onTap: () {
              if (widget.onTabChange != null) {
                widget.onTabChange!(1);
              }
            },
          ),
          _buildSettingsTile(
            Icons.cleaning_services_outlined,
            'إدارة الخدمات',
            subtitle: 'تعديل أسعار وخيارات الخدمات المتاحة',
            onTap: () {},
          ),
          _buildSettingsTile(
            Icons.local_offer_outlined,
            'العروض والكوبونات',
            subtitle: 'إضافة وإدارة عروض الخصم الترويجية',
            onTap: () {
              if (widget.onTabChange != null) {
                widget.onTabChange!(2);
              }
            },
          ),
          _buildSettingsTile(
            Icons.bar_chart_outlined,
            'التقارير والإحصائيات',
            subtitle: 'الاطلاع على تقارير الأداء والمبيعات',
            onTap: () {},
          ),
          _buildSettingsTile(
            Icons.notifications_outlined,
            'الإشعارات',
            subtitle: 'إرسال التنبيهات العامة للمستخدمين',
            onTap: () {},
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // التفضيلات والإعدادات
          _buildSettingsHeader('التفضيلات والإعدادات'),
          _buildSettingsTile(
            Icons.lock_outline,
            'تغيير كلمة المرور',
            subtitle: 'تحديث كلمة المرور لحماية الحساب',
            onTap: () {},
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController().themeMode,
            builder: (context, themeMode, child) {
              final isDarkTheme = themeMode == ThemeMode.dark ||
                  (themeMode == ThemeMode.system &&
                      MediaQuery.of(context).platformBrightness == Brightness.dark);
              return _buildSwitchTile(
                'الوضع الليلي',
                isDarkTheme,
                (_) => ThemeController().toggleTheme(),
              );
            },
          ),
          
          const Divider(height: 40),
          _buildSettingsTile(
            Icons.logout,
            'تسجيل الخروج',
            subtitle: 'تسجيل خروج من الحساب الحالي',
            color: AppColors.error,
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {String? subtitle, Color? color, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      secondary: Icon(
        value ? Icons.dark_mode : Icons.light_mode,
        color: value ? AppColors.primary : Colors.grey,
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
      activeThumbColor: AppColors.primary,
    );
  }
}
