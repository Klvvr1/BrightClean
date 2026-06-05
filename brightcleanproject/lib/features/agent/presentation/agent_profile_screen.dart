import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/widgets/profile/profile_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/exceptions.dart';

class AgentProfileScreen extends StatefulWidget {
  const AgentProfileScreen({super.key});

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  String _userName = 'مغسلة الخليج';
  String _userPhone = '+966 50 123 4567';
  String _userEmail = 'laundry@example.com';
  bool _isOpen = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'مغسلة الخليج';
        _userPhone = prefs.getString('user_phone') ?? '+966 50 123 4567';
        _userEmail = prefs.getString('user_email') ?? 'laundry@example.com';
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
      await prefs.remove('user_email');
      await prefs.remove('user_role');
      if (mounted) context.go('/login');
    }
  }

  Future<void> _showSubscribeServicesDialog() async {
    final TextEditingController serviceIdsController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final theme = Theme.of(ctx);
          return AlertDialog(
            title: const Text('اشتراك في خدمات'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أدخل معرفات الخدمات (IDs) المفصولة بفاصلة',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: serviceIdsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'مثال: 1, 2, 3',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'الخدمات ستظهر للعملاء إذا كان حساب المغسلة مفعلا.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final raw = serviceIdsController.text.trim();

                        // Capture context-sensitive objects BEFORE any return
                        final messenger = ScaffoldMessenger.of(context);

                        if (raw.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('الرجاء إدخال معرفات الخدمات'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        // Parse comma-separated IDs
                        final ids = raw
                            .split(',')
                            .map((s) => int.tryParse(s.trim()))
                            .where((id) => id != null)
                            .map((id) => id!)
                            .toList();

                        if (ids.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('الرجاء إدخال معرف خدمة واحد على الأقل رقمي صحيح'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        // Capture context-sensitive objects BEFORE the async gap
                        final nav = Navigator.of(ctx);

                        setDialogState(() => isSubmitting = true);
                        try {
                          final apiClient = BaseApiClient();
                          await apiClient.post(
                            '/api/agentservices',
                            body: {'serviceIDs': ids},
                          );
                          nav.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'تم حفظ الخدمات، وستظهر للعملاء إذا كان الحساب مفعلا.',
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } on ServerException catch (e) {
                          setDialogState(() => isSubmitting = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('فشل الاشتراك: ${e.message ?? "خطأ في الخادم"}'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('حدث خطأ: $e'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('تقديم الطلب'),
              ),
            ],
          );
        },
      ),
    ).then((_) => serviceIdsController.dispose());
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
            subtitle: 'شريك معتمد في برايت كلين',
            statusBadge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isOpen ? AppColors.success : AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isOpen ? 'مفتوح' : 'مغلق',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildWorkStatusToggle(),
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

  Widget _buildWorkStatusToggle() {
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
                  color: _isOpen ? AppColors.success : AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'حالة العمل',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Switch.adaptive(
            value: _isOpen,
            activeTrackColor: AppColors.success,
            onChanged: (v) => setState(() => _isOpen = v),
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
            icon: Icons.person_outline,
            label: 'الاسم',
            value: _userName,
          ),
          const Divider(height: 1),
          AccountInfoCard(
            icon: Icons.phone_outlined,
            label: 'رقم الهاتف',
            value: _userPhone,
          ),
          const Divider(height: 1),
          AccountInfoCard(
            icon: Icons.email_outlined,
            label: 'البريد الإلكتروني',
            value: _userEmail,
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
            title: 'الطلبات المكلف بها',
            onTap: () {},
          ),
          const Divider(height: 1),
          ProfileMenuTile(
            icon: Icons.history_outlined,
            title: 'سجل العمليات',
            onTap: () {},
          ),
          const Divider(height: 1),
          ProfileMenuTile(
            icon: Icons.notifications_outlined,
            title: 'الإشعارات',
            onTap: () {},
          ),
          const Divider(height: 1),
          ProfileMenuTile(
            icon: Icons.local_laundry_service_outlined,
            title: 'اشتراك في خدمات',
            subtitle: 'أضف خدمات جديدة لمعرض عروضك',
            onTap: _showSubscribeServicesDialog,
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
