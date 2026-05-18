import 'package:flutter/material.dart';
import 'package:brightcleanproject/core/theme/app_spacing.dart';

import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/controllers/theme_controller.dart';
import '../../../core/controllers/language_controller.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _selectedIndex = 0;
  bool _isOnline = false;
  Map<String, bool> _completedTasks = {};

  // Mock data for user profile
  String _userName = 'سائق برايت كلين';
  String _userPhone = '0533333333';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final isAr = LanguageController().isArabic;
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    // Load completed tasks
    final keys = prefs.getKeys();
    final completed = <String, bool>{};
    for (var key in keys) {
      if (key.startsWith('task_completed_')) {
        completed[key.replaceFirst('task_completed_', '')] =
            prefs.getBool(key) ?? false;
      }
    }

    setState(() {
      final savedName = prefs.getString('user_name');
      final isDefaultName = prefs.getBool('user_name_is_default') ?? true;

      // Only localize if explicitly marked as default
      if (savedName == null ||
          isDefaultName ||
          savedName == 'سائق برايت كلين' ||
          savedName == 'Bright Clean Driver') {
        _userName = isAr ? 'سائق برايت كلين' : 'Bright Clean Driver';
        // Keep the flag set to true since we're using a default name
        prefs.setBool('user_name_is_default', true);
      } else {
        _userName = savedName;
      }
      _userPhone = prefs.getString('user_phone') ?? '0533333333';
      _completedTasks = completed;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index != 0) {
      _loadUserData(); // Refresh data when switching tabs
    }
  }

  // --- Home Tab (Incoming Orders) ---
  Widget _buildHomeTab() {
    final isAr = LanguageController().isArabic;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Welcome Section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              PopupMenuButton<int>(
                onSelected: (value) {
                  if (value == 1) {
                    setState(() => _selectedIndex = 2); // Go to Profile tab
                  } else if (value == 2) {
                    _showLogoutDialog();
                  }
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 1,
                    child: ListTile(
                      leading: Icon(Icons.person_outline,
                          color: theme.colorScheme.primary),
                      title: Text(isAr ? 'حسابي' : 'My Account'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 2,
                    child: ListTile(
                      leading:
                          const Icon(Icons.logout, color: Colors.redAccent),
                      title: Text(isAr ? 'تسجيل الخروج' : 'Logout',
                          style: const TextStyle(color: Colors.redAccent)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.person,
                        color:
                            isDark ? Colors.white : theme.colorScheme.primary,
                        size: 35),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'مرحباً بك،' : 'Welcome back,',
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? Colors.white : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _isOnline
                      ? AppColors.success.withValues(alpha: 0.1)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isOnline
                        ? AppColors.success.withValues(alpha: 0.2)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _isOnline
                            ? AppColors.success
                            : (isDark ? Colors.white : Colors.grey),
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (_isOnline)
                            BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.5),
                                blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      isAr
                          ? (_isOnline ? 'نشط' : 'غير نشط')
                          : (_isOnline ? 'Active' : 'Offline'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _isOnline
                            ? AppColors.success
                            : (isDark ? Colors.white : Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Work Status Toggle
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr
                      ? 'وضعية العمل (استقبال الطلبات)'
                      : 'Work Mode (Accepting Orders)',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87),
                ),
                Switch.adaptive(
                  value: _isOnline,
                  activeTrackColor: AppColors.success,
                  onChanged: (v) => setState(() => _isOnline = v),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _isOnline
              ? _buildOnlineContent(isAr, isDark)
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_off_outlined,
                          size: 80,
                          color: isDark
                              ? Colors.white12
                              : Colors.grey.withValues(alpha: 0.2)),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        isAr
                            ? 'قم بتفعيل وضع العمل للبدء'
                            : 'Enable Work Mode to Start',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            color: isDark ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _refreshOrders() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      _loadUserData();
    }
  }

  Widget _buildOnlineContent(bool isAr, bool isDark) {
    List<Widget> availableOrdersWidgets = [];

    // Only show task if not completed
    if (_completedTasks['1026'] != true) {
      availableOrdersWidgets.add(
        _buildOrderCard(
          orderId: '1026',
          time: isAr ? 'منذ 5 دقائق' : '5 mins ago',
          from: isAr ? 'المغسلة الذهبية' : 'Golden Laundry',
          to: isAr
              ? 'منزل العميل - برج السلام'
              : 'Customer House - Salam Tower',
          type: isAr ? 'ملابس' : 'Clothes',
          isNew: true,
          workflow: 1, // Pickup
        ),
      );
    }

    if (_completedTasks['1027'] != true) {
      availableOrdersWidgets.add(
        _buildOrderCard(
          orderId: '1027',
          time: isAr ? 'منذ 15 دقيقة' : '15 mins ago',
          from: isAr ? 'مغسلة النور' : 'Al Noor Laundry',
          to: isAr ? 'فلل النخيل' : 'Palm Villas',
          type: isAr ? 'سجاد' : 'Carpets',
          isNew: true,
          workflow: 2, // Delivery
        ),
      );
    }

    if (availableOrdersWidgets.isEmpty) {
      // Empty state when online but no orders
      return RefreshIndicator(
        onRefresh: _refreshOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            _buildEarningsCard(),
            const SizedBox(height: 40),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 80,
                      color: isDark
                          ? Colors.white
                          : Colors.grey.withValues(alpha: 0.2)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    isAr
                        ? 'لا توجد طلبات متاحة حالياً'
                        : 'No Available Orders Yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isAr ? 'اسحب للأسفل للتحديث' : 'Pull down to refresh',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Has orders - show list with refresh
    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _buildEarningsCard(),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              isAr ? 'الطلبات المتاحة' : 'Available Requests',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...availableOrdersWidgets,
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    final isAr = LanguageController().isArabic;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'أرباحك اليوم' : 'Today\'s Earnings',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isAr ? '120.50 ر.ي' : '120.50 YER',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.payments_outlined,
                  color: Colors.white, size: 35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required String orderId,
    required String time,
    required String from,
    required String to,
    required String type,
    bool isNew = false,
    bool isCompleted = false,
    required int workflow,
  }) {
    final isAr = LanguageController().isArabic;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (workflow == 1
                                ? AppColors.primary
                                : AppColors.secondary)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        workflow == 1
                            ? (isAr ? 'استلام' : 'Pickup')
                            : (isAr ? 'توصيل' : 'Delivery'),
                        style: TextStyle(
                          color: workflow == 1
                              ? AppColors.primary
                              : AppColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // Order Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        type,
                        style: const TextStyle(
                          color: AppColors.tertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text('${isAr ? 'طلب' : 'Order'} #$orderId',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87)),
                  ],
                ),
                Text(time,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey,
                        fontSize: 12)),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.trip_origin,
                    size: 16,
                    color: isDark ? Colors.white : theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: Text('${isAr ? 'من:' : 'From:'} $from',
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87))),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.location_on,
                    size: 16,
                    color: isDark ? Colors.white : AppColors.secondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: Text('${isAr ? 'إلى:' : 'To:'} $to',
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87))),
              ],
            ),
            if (!isCompleted) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await context.push(
                      '/driver_tracking/$orderId',
                      extra: {'workflow': workflow},
                    );
                    _loadUserData(); // Refresh when coming back
                  },
                  child: Text(isNew
                      ? (isAr ? 'قبول الطلب' : 'Accept Order')
                      : (isAr ? 'متابعة الطلب' : 'Track Order')),
                ),
              ),
            ],
            if (isCompleted) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAr ? 'تم بنجاح' : 'Completed Successfully',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.success, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- My Orders Tab (Current/Previous Toggle) ---
  Widget _buildMyOrdersTab() {
    final isAr = LanguageController().isArabic;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Evaluate Current Orders logic
    List<Widget> currentOrdersWidgets = [];
    if (_completedTasks['1020'] != true) {
      currentOrdersWidgets.add(
        _buildOrderCard(
          orderId: '1020',
          time: isAr ? 'قيد التوصيل' : 'In Transit',
          from: isAr ? 'مغسلة النور' : 'Al Noor Laundry',
          to: isAr ? 'منطقة المارينا' : 'Marina Area',
          type: isAr ? 'ملابس' : 'Clothes',
          workflow: 2,
        ),
      );
    }
    if (currentOrdersWidgets.isEmpty) {
      currentOrdersWidgets.add(Center(
          child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(isAr ? 'لا توجد طلبات جارية' : 'No current orders',
            style: TextStyle(color: isDark ? Colors.white : Colors.grey)),
      )));
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: theme.cardColor,
            child: TabBar(
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: isDark ? Colors.white : Colors.grey,
              indicatorColor: theme.colorScheme.primary,
              tabs: [
                Tab(text: isAr ? 'الطلبات الحالية' : 'Current Orders'),
                Tab(text: isAr ? 'الطلبات السابقة' : 'Previous Orders'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Current Orders (Not completed)
                ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: currentOrdersWidgets,
                ),
                // Previous Orders (Completed)
                ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    if (_completedTasks['1026'] == true)
                      _buildOrderCard(
                        orderId: '1026',
                        time: isAr ? 'اليوم' : 'Today',
                        from: isAr ? 'المغسلة الذهبية' : 'Golden Laundry',
                        to: isAr ? 'منزل العميل' : 'Customer House',
                        type: isAr ? 'ملابس' : 'Clothes',
                        isCompleted: true,
                        workflow: 1,
                      ),
                    if (_completedTasks['1027'] == true)
                      _buildOrderCard(
                        orderId: '1027',
                        time: isAr ? 'اليوم' : 'Today',
                        from: isAr ? 'مغسلة النور' : 'Al Noor Laundry',
                        to: isAr ? 'فلل النخيل' : 'Palm Villas',
                        type: isAr ? 'سجاد' : 'Carpets',
                        isCompleted: true,
                        workflow: 2,
                      ),
                    _buildOrderCard(
                      orderId: '985',
                      time: isAr ? 'أمس 04:30 م' : 'Yesterday 04:30 PM',
                      from: isAr ? 'مغسلة الرمال' : 'Al Rimal Laundry',
                      to: isAr ? 'جميرا' : 'Jumeirah',
                      type: isAr ? 'ملابس' : 'Clothes',
                      isCompleted: true,
                      workflow: 2,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Profile Tab ---
  Widget _buildProfileTab() {
    final isAr = LanguageController().isArabic;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Profile Header
        Center(
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: theme.colorScheme.primary, width: 2),
                ),
                child: Icon(Icons.person,
                    size: 60,
                    color: isDark ? Colors.white : theme.colorScheme.primary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _userName,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87),
              ),
              Text(
                isAr ? 'شريك توصيل معتمد' : 'Certified Delivery Partner',
                style: TextStyle(color: isDark ? Colors.white : Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // Info Cards
        _buildProfileItem(Icons.phone_outlined,
            isAr ? 'رقم الهاتف' : 'Phone Number', _userPhone),
        _buildProfileItem(
            Icons.email_outlined,
            isAr ? 'البريد الإلكتروني' : 'Email Address',
            'driver@brightclean.com'),
        _buildProfileItem(
            Icons.drive_eta_outlined,
            isAr ? 'نوع المركبة' : 'Vehicle Type',
            isAr ? 'سيارة صالون' : 'Sedan Car'),
        _buildProfileItem(Icons.confirmation_number_outlined,
            isAr ? 'رقم اللوحة' : 'Plate Number', 'A 12345'),

        const SizedBox(height: AppSpacing.lg),

        // التفضيلات
        _buildSettingsHeader(isAr ? 'التفضيلات' : 'Preferences'),
        ListTile(
          leading: Icon(Icons.language, color: isDark ? Colors.white : AppColors.primary),
          title: Text(isAr ? 'لغة التطبيق' : 'App Language', style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isAr ? 'العربية' : 'English', 
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.primary, 
                fontWeight: FontWeight.bold
              )
            ),
          ),
          onTap: () {
            setState(() {
              LanguageController().toggleLanguage();
              _loadUserData();
            });
          },
        ),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController().themeMode,
          builder: (context, themeMode, child) {
            final isDarkTheme = themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
            return _buildSwitchTile(
              isAr ? 'الوضع الليلي' : 'Night Mode',
              isDarkTheme,
              (_) => ThemeController().toggleTheme(),
              icon: isDarkTheme ? Icons.dark_mode : Icons.light_mode,
            );
          },
        ),

        const Divider(height: 40),

        // Logout Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: Text(isAr ? 'تسجيل الخروج' : 'Logout',
                style: const TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged, {IconData? icon}) {
    return SwitchListTile(
      secondary: Icon(
        icon ?? (value ? Icons.dark_mode : Icons.light_mode), 
        color: value ? AppColors.primary : Colors.grey
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
      activeThumbColor: AppColors.primary,
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: isDark ? Colors.white : theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey,
                      fontSize: 12)),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final isAr = LanguageController().isArabic;
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAr ? 'تسجيل الخروج' : 'Logout'),
        content: Text(isAr
            ? 'هل أنت متأكد أنك تريد تسجيل الخروج؟'
            : 'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              // Only clear authentication-related keys, preserve theme/locale settings
              await prefs.remove('auth_token');
              await prefs.remove('refresh_token');
              await prefs.remove('user_id');
              await prefs.remove('user_name');
              await prefs.remove('user_phone');
              await prefs.remove('user_name_is_default');

              if (context.mounted) {
                context.go('/login');
              }
            },
            child: Text(isAr ? 'خروج' : 'Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = LanguageController().isArabic;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          isAr ? 'برايت كلين' : 'Bright Clean',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        elevation: 4,
        shadowColor: Colors.black26,
        backgroundColor: AppColors.primary,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          _buildMyOrdersTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDark ? Colors.white : Colors.grey.shade600,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.cardColor,
          elevation: 0,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined, size: 26),
              activeIcon: const Icon(Icons.home, size: 26),
              label: isAr ? 'الرئيسية' : 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.assignment_outlined, size: 26),
              activeIcon: const Icon(Icons.assignment, size: 26),
              label: isAr ? 'طلباتي' : 'Orders',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline, size: 26),
              activeIcon: const Icon(Icons.person, size: 26),
              label: isAr ? 'حسابي' : 'My Account',
            ),
          ],
        ),
      ),
    );
  }
}
