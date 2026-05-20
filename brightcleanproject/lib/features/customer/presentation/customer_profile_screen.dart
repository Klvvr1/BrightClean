import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'edit_account_screen.dart';
import 'change_password_screen.dart';
import 'addresses_screen.dart';
import 'notifications_screen.dart';
import 'my_orders_screen.dart';
import 'models/user_profile.dart';
import 'widgets/wallet_section.dart';
import 'widgets/help_center_bottom_sheet.dart';
import '../../../core/widgets/profile/profile_widgets.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/controllers/theme_controller.dart';
import '../../../core/theme/app_colors.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  UserProfile _currentUser = const UserProfile(
    name: 'أحمد محمد',
    phone: '+971 50 123 4567',
    walletBalance: '0 ريال يمني',
  );

  @override
  void initState() {
    super.initState();
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'أحمد محمد';
    final phone = prefs.getString('user_phone') ?? '+971 50 123 4567';
    final walletBalance = prefs.getString('wallet_balance') ?? '0 ريال يمني';
    final imagePath = prefs.getString('profile_image_path');

    if (mounted) {
      setState(() {
        _currentUser = UserProfile(
          name: name,
          phone: phone,
          walletBalance: walletBalance,
          imagePath: imagePath,
        );
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
          content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج من التطبيق؟'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('إلغاء', style: TextStyle(color: t.colorScheme.onSurface.withValues(alpha: 0.6))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: t.colorScheme.error,
                foregroundColor: t.colorScheme.onError,
              ),
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
      await prefs.remove('user_email');
      await prefs.remove('wallet_balance');
      await prefs.remove('profile_image_path');
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
            name: _currentUser.name,
            subtitle: _currentUser.phone,
            imagePath: _currentUser.imagePath,
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // حسابي
          _buildSettingsHeader('حسابي'),
          
          // Wallet section styled as a flat card or tile
          WalletSection(balance: _currentUser.walletBalance),
          const SizedBox(height: AppSpacing.sm),

          _buildSettingsTile(
            Icons.person_outline,
            'تعديل الحساب',
            subtitle: 'تعديل بيانات الحساب الشخصي',
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditAccountScreen()),
              );
              await _loadUserFromPrefs();
            },
          ),
          _buildSettingsTile(
            Icons.receipt_long_outlined,
            'الطلبات',
            subtitle: 'عرض طلباتي السابقة والجاري تنفيذها',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
              );
            },
          ),
          _buildSettingsTile(
            Icons.location_on_outlined,
            'العناوين المحفوظة',
            subtitle: 'إدارة عناوين التوصيل الخاصة بك',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddressesScreen()),
              );
            },
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // التفضيلات والإعدادات
          _buildSettingsHeader('التفضيلات والإعدادات'),
          _buildSettingsTile(
            Icons.notifications_outlined,
            'الإشعارات',
            subtitle: 'التحكم بإشعارات وتنبيهات التطبيق',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          _buildSettingsTile(
            Icons.lock_outline,
            'تغيير كلمة المرور',
            subtitle: 'تحديث كلمة المرور لحماية الحساب',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
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

          const SizedBox(height: AppSpacing.lg),
          
          // الدعم والمساعدة
          _buildSettingsHeader('الدعم والمساعدة'),
          _buildSettingsTile(
            Icons.support_agent,
            'مركز المساعدة',
            subtitle: 'تواصل مع الدعم الفني للمساعدة',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const HelpCenterBottomSheet(),
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
