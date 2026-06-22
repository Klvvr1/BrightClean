import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/widgets/profile/profile_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/network/api_client.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  String _userName = 'المندوب';
  String _userPhone = '0533333333';
  String _userEmail = '';
  String _vehicle = '';
  String _plateNumber = '';
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic>? profileResponse;
    try {
      final response = await BaseApiClient().get('/api/users/me');
      if (response is Map<String, dynamic>) {
        profileResponse = response;
      }
    } catch (_) {
      profileResponse = null;
    }
    if (mounted) {
      setState(() {
        final storedName = prefs.getString('user_name') ?? '';
        _userName = storedName.trim().isEmpty ? 'المندوب' : storedName;
        _userPhone = prefs.getString('user_phone') ?? '0533333333';
        final profile = profileResponse?['profile'];
        final driver = profileResponse?['driver'];
        if (profile is Map<String, dynamic>) {
          final firstName = profile['firstName']?.toString() ?? '';
          final lastName = profile['lastName']?.toString() ?? '';
          final serverName = '$firstName $lastName'.trim();
          if (serverName.isNotEmpty) {
            _userName = serverName;
          }
          _userPhone = profile['phoneNo']?.toString() ?? _userPhone;
          _userEmail = profile['email']?.toString() ?? '';
        }
        if (driver is Map<String, dynamic>) {
          final make = driver['vehicleMake']?.toString() ?? '';
          final model = driver['vehicleModel']?.toString() ?? '';
          _vehicle = '$make $model'.trim();
          if (_vehicle.isEmpty) {
            _vehicle = driver['vehicleType']?.toString() ?? '';
          }
          _plateNumber = driver['plateNumber']?.toString() ?? '';
        }
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
            subtitle: 'شريك توصيل معتمد',
            statusBadge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isAvailable ? AppColors.success : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isAvailable ? 'متاح' : 'غير متاح',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildAvailabilityToggle(),
          const SizedBox(height: AppSpacing.md),
          _buildInfoSection(),
          const SizedBox(height: AppSpacing.md),
          _buildOrdersSection(),
          const SizedBox(height: AppSpacing.md),
          _buildSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _isAvailable ? AppColors.success : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'حالة التوفر',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Switch.adaptive(
            value: _isAvailable,
            activeTrackColor: AppColors.success,
            onChanged: (v) => setState(() => _isAvailable = v),
          ),
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
            value: _userEmail.isEmpty ? '-' : _userEmail,
          ),
          const Divider(height: 1),
          AccountInfoCard(
            icon: Icons.drive_eta_outlined,
            label: 'نوع المركبة',
            value: _vehicle.isEmpty ? '-' : _vehicle,
          ),
          const Divider(height: 1),
          AccountInfoCard(
            icon: Icons.confirmation_number_outlined,
            label: 'رقم اللوحة',
            value: _plateNumber.isEmpty ? '-' : _plateNumber,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersSection() {
    return Container(
      decoration: AppStyles.surface(context),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          ProfileMenuTile(
            icon: Icons.assignment_outlined,
            title: 'الطلبات المسندة',
            onTap: () {},
          ),
          const Divider(height: 1),
          ProfileMenuTile(
            icon: Icons.history_outlined,
            title: 'سجل التوصيلات',
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
