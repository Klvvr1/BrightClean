import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/data/providers/auth_provider.dart';
import '../data/providers/cart_provider.dart';
import '../data/providers/order_provider.dart';
import 'edit_account_screen.dart';
import 'change_password_screen.dart';
import 'addresses_screen.dart';
import 'notifications_screen.dart';
import 'my_orders_screen.dart';
import 'models/user_profile.dart';
import 'widgets/wallet_section.dart';
import '../data/providers/wallet_provider.dart';
import 'widgets/help_center_bottom_sheet.dart';
import '../../../core/widgets/profile/profile_widgets.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/controllers/theme_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/language_controller.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchBalance();
    });
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'أحمد محمد';
    final phone = prefs.getString('user_phone') ?? '+971 50 123 4567';
    final imagePath = prefs.getString('profile_image_path');

    if (mounted) {
      setState(() {
        _currentUser = UserProfile(
          name: name,
          phone: phone,
          walletBalance: '',
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
      await Provider.of<AuthProvider>(context, listen: false).logout(
        Provider.of<CartProvider>(context, listen: false),
        Provider.of<OrderProvider>(context, listen: false),
      );
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = LanguageController().isArabic;
    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'حسابي' : 'My Account'),
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
          Consumer<WalletProvider>(
            builder: (context, walletProvider, child) => WalletSection(
              balance: walletProvider.isLoading
                  ? 'جارٍ التحميل...'
                  : walletProvider.balanceFormatted,
              onDepositSuccess: () => walletProvider.fetchBalance(),
            ),
          ),
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
            isArabic ? 'تغيير كلمة المرور' : 'Change Password',
            subtitle: isArabic ? 'تحديث كلمة المرور لحماية الحساب' : 'Update password to protect your account',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.language, color: theme.brightness == Brightness.dark ? Colors.white : AppColors.primary),
            title: Text(
              isArabic ? 'لغة التطبيق' : 'App Language',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? Colors.white10 : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isArabic ? 'العربية' : 'English', 
                style: TextStyle(
                  color: theme.brightness == Brightness.dark ? Colors.white : AppColors.primary, 
                  fontWeight: FontWeight.bold
                )
              ),
            ),
            onTap: null,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade600,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {String? subtitle, Color? color, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: color ?? (isDark ? Colors.white : AppColors.primary)),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: color ?? (isDark ? Colors.white : null)),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : null)) : null,
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.white70 : null),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SwitchListTile(
      secondary: Icon(
        value ? Icons.dark_mode : Icons.light_mode,
        color: value 
            ? (isDark ? Colors.white : AppColors.primary) 
            : (isDark ? Colors.white38 : Colors.grey),
      ),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : null)),
      value: value,
      onChanged: onChanged,
      activeTrackColor: isDark ? Colors.white30 : AppColors.primary.withValues(alpha: 0.5),
      activeThumbColor: isDark ? Colors.white : AppColors.primary,
    );
  }
}
