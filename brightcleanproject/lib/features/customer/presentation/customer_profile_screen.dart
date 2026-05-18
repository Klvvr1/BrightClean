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
import '../../../core/theme/app_styles.dart';
import '../../../core/controllers/theme_controller.dart';

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
          const SizedBox(height: AppSpacing.xxl),
          _buildAccountSection(),
          const SizedBox(height: AppSpacing.md),
          _buildActionsSection(),
          const SizedBox(height: AppSpacing.md),
          _buildSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      decoration: AppStyles.surface(context),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          WalletSection(balance: _currentUser.walletBalance),
          const Divider(height: 1),
          ProfileMenuTile(
            icon: Icons.receipt_long_outlined,
            title: 'الطلبات',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Container(
      decoration: AppStyles.surface(context),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          ProfileMenuTile(
            icon: Icons.person_outline,
            title: 'تعديل الحساب',
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditAccountScreen()),
              );
              await _loadUserFromPrefs();
            },
          ),
          const Divider(height: 1),
          ProfileMenuTile(
            icon: Icons.location_on_outlined,
            title: 'العناوين المحفوظة',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddressesScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ProfileMenuTile(
            icon: Icons.notifications_outlined,
            title: 'الإشعارات',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
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
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ProfileMenuTile(
            icon: Icons.support_agent,
            title: 'مركز المساعدة',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const HelpCenterBottomSheet(),
              );
            },
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
