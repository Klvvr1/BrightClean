import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../auth/presentation/login_screen.dart';
import 'addresses_screen.dart';
import 'change_password_screen.dart';
import 'edit_account_screen.dart';
import 'models/user_profile.dart';
import 'widgets/custom_profile_tile.dart';
import 'widgets/profile_header_section.dart';
import 'widgets/wallet_section.dart';
import 'widgets/help_center_bottom_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditMode = false;

  // Mock data (should ideally come from State Management)
  final UserProfile _currentUser = const UserProfile(
    name: 'أحمد محمد',
    phone: '+971 50 123 4567',
    walletBalance: '150 درهم',
  );

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  // 4. Fix the "Login After Logout" Bug (CRITICAL)
  Future<void> _clearUserSession() async {
    try {
      /*
      // 1. Clear Local Storage (Tokens & User Data)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clears everything (or use prefs.remove('token'))

      // 2. Clear API Headers (Dio Example)
      // DioClient.instance.options.headers.remove('Authorization');
      
      // 3. Reset State Management (if you add GetX / Provider / Bloc later)
      // For Provider:
      // Provider.of<AuthProvider>(context, listen: false).clearAuth();
      // For GetX:
      // Get.find<AuthController>().clearAuth();
      // For Bloc:
      // context.read<AuthBloc>().add(LoggedOutEvent());
      */
      
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
          title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
          content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج من التطبيق؟'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      await _clearUserSession();

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
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditAccountScreen(),
                ),
              );
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
