import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'addresses_screen.dart';
import 'change_password_screen.dart';
import 'edit_account_screen.dart';
import 'models/user_profile.dart';
import 'widgets/custom_profile_tile.dart';
import 'widgets/profile_header_section.dart';
import 'widgets/wallet_section.dart';
import 'widgets/help_center_bottom_sheet.dart';
import 'package:brightcleanproject/core/controllers/theme_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditMode = false;

  // Mock data (should ideally come from State Management)
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

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  Future<void> _handleEditAvatar() async {
    // Navigate to edit account screen or open image picker
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EditAccountScreen(),
      ),
    );
    await _loadUserFromPrefs();
  }

  // 4. Clear user session and persisted data on logout
  Future<void> _clearUserSession() async {
    try {
      // 1. Clear Local Storage (Tokens & User Data)
      final prefs = await SharedPreferences.getInstance();

      // Read userId before removing it
      final userId = prefs.getString('user_id') ?? 'default_user';

      // Remove specific auth and user-scoped keys
      await prefs.remove('auth_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_phone');
      await prefs.remove('user_email');
      await prefs.remove('wallet_balance');
      await prefs.remove('profile_image_path');

      // Remove user-scoped data (addresses) using the stored userId
      await prefs.remove('user_saved_addresses_$userId');

      // Reset in-memory state to defaults
      if (mounted) {
        setState(() {
          _currentUser = const UserProfile(
            name: 'أحمد محمد',
            phone: '+971 50 123 4567',
            walletBalance: '0 ريال يمني',
          );
        });
      }

      // 2. Clear API Headers (if using Dio or http client)
      // TODO: Add when API client is implemented
      // Example for Dio:
      // DioClient.instance.options.headers.remove('Authorization');
      // Example for http:
      // HttpClient.instance.clearAuthHeader();

      // 3. Reset State Management (if you add GetX / Provider / Bloc later)
      // For Provider:
      // if (mounted) Provider.of<AuthProvider>(context, listen: false).clearAuth();
      // For GetX:
      // Get.find<AuthController>().clearAuth();
      // For Bloc:
      // if (mounted) context.read<AuthBloc>().add(LoggedOutEvent());

      debugPrint('User session completely cleared');
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
  }

  Future<void> _showLogoutConfirmationDialog() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
          content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج من التطبيق؟'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      // Step 1: Actually completely clear the session data and token!
      try {
        await _clearUserSession();
      } catch (e) {
        debugPrint('Error during logout: $e');
        // Continue with logout even if clearing session fails
      }

      if (!mounted) return;

      // Step 2: Use GoRouter's go() instead of Navigator to completely destroy routing stack
      // Because your app uses GoRouter, using pushAndRemoveUntil causes routing state issues.
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit),
            onPressed: _toggleEditMode,
            tooltip: _isEditMode ? 'حفظ التعديلات' : 'تعديل الملف',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ProfileHeaderSection(
            user: _currentUser,
            isEditMode: _isEditMode,
            onEditAvatarPressed: _isEditMode ? _handleEditAvatar : null,
          ),
          const SizedBox(height: 32),
          WalletSection(balance: _currentUser.walletBalance),
          const SizedBox(height: 16),
          _buildSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          CustomProfileTile(
            icon: Icons.person_outline,
            title: 'تعديل الحساب',
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditAccountScreen(),
                ),
              );
              await _loadUserFromPrefs();
            },
          ),
          const Divider(height: 1),
          CustomProfileTile(
            icon: Icons.location_on,
            title: 'العناوين المحفوظة',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddressesScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          CustomProfileTile(
            icon: Icons.lock,
            title: 'تغيير كلمة المرور',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          CustomProfileTile(
            icon: Icons.support_agent,
            title: 'مركز المساعدة',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const HelpCenterBottomSheet(),
              );
            },
          ),
          const Divider(height: 1),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController().themeMode,
            builder: (context, themeMode, child) {
              // Note: themeMode might be ThemeMode.system, we assume dark mode is active
              // if it's explicitly ThemeMode.dark. Alternatively, you can use MediaQuery for system check.
              final isDarkMode = themeMode == ThemeMode.dark ||
                  (themeMode == ThemeMode.system &&
                      MediaQuery.of(context).platformBrightness ==
                          Brightness.dark);

              return CustomProfileTile(
                icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
                title: 'الوضع الليلي',
                onTap: () {
                  ThemeController().toggleTheme();
                },
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (value) {
                    ThemeController().toggleTheme();
                  },
                ),
                onTap: () {
                  ThemeController().toggleTheme();
                },
              );
            },
          ),
          const Divider(height: 1),
          CustomProfileTile(
            icon: Icons.logout,
            title: 'تسجيل الخروج',
            isDestructive: true,
            onTap: _showLogoutConfirmationDialog,
          ),
        ],
      ),
    );
  }
}
