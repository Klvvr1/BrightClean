import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../controllers/theme_controller.dart';
import '../../../../controllers/language_controller.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _selectedIndex = 0;
  bool _isOnline = false;

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
    setState(() {
      final savedName = prefs.getString('user_name');
      // Force localize default name
      if (savedName == null || savedName == 'سائق برايت كلين' || savedName == 'Bright Clean Driver') {
        _userName = isAr ? 'سائق برايت كلين' : 'Bright Clean Driver';
      } else {
        _userName = savedName;
      }
      _userPhone = prefs.getString('user_phone') ?? '0533333333';
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 1,
                    child: ListTile(
                      leading: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                      title: Text(isAr ? 'الملف الشخصي' : 'Profile'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 2,
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.redAccent),
                      title: Text(isAr ? 'تسجيل الخروج' : 'Logout', style: const TextStyle(color: Colors.redAccent)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.person, color: isDark ? Colors.white : theme.colorScheme.primary, size: 35),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'مرحباً بك،' : 'Welcome back,',
                      style: TextStyle(color: isDark ? Colors.white : Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _isOnline ? AppColors.success.withValues(alpha: 0.1) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isOnline ? AppColors.success.withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _isOnline ? AppColors.success : (isDark ? Colors.white : Colors.grey),
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (_isOnline) BoxShadow(color: AppColors.success.withValues(alpha: 0.5), blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAr ? (_isOnline ? 'نشط' : 'غير نشط') : (_isOnline ? 'Active' : 'Offline'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _isOnline ? AppColors.success : (isDark ? Colors.white : Colors.grey),
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
                  isAr ? 'وضعية العمل (استقبال الطلبات)' : 'Work Mode (Accepting Orders)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Switch.adaptive(
                  value: _isOnline,
                  activeColor: AppColors.success,
                  onChanged: (v) => setState(() => _isOnline = v),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _isOnline
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    _buildEarningsCard(),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        isAr ? 'الطلبات المتاحة' : 'Available Requests',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildOrderCard(
                      orderId: '1026',
                      time: isAr ? 'منذ 5 دقائق' : '5 mins ago',
                      from: isAr ? 'المغسلة الذهبية' : 'Golden Laundry',
                      to: isAr ? 'منزل العميل - برج السلام' : 'Customer House - Salam Tower',
                      isNew: true,
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_off_outlined, size: 80, color: isDark ? Colors.white : Colors.grey.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text(
                        isAr ? 'قم بتفعيل وضع العمل للبدء' : 'Enable Work Mode to Start',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
        ),
      ],
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
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr ? '120.50 درهم' : '120.50 AED',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.payments_outlined, color: Colors.white, size: 35),
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
    bool isNew = false,
    bool isCompleted = false,
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
                Text('${isAr ? 'طلب' : 'Order'} #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(time, style: TextStyle(color: isDark ? Colors.white : Colors.grey, fontSize: 12)),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.trip_origin, size: 16, color: isDark ? Colors.white : theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text('${isAr ? 'من:' : 'From:'} $from', style: const TextStyle(fontSize: 14))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: isDark ? Colors.white : AppColors.secondary),
                const SizedBox(width: 12),
                Expanded(child: Text('${isAr ? 'إلى:' : 'To:'} $to', style: const TextStyle(fontSize: 14))),
              ],
            ),
            if (!isCompleted) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/driver_tracking/$orderId'),
                  child: Text(isNew 
                    ? (isAr ? 'قبول الطلب' : 'Accept Order') 
                    : (isAr ? 'متابعة الطلب' : 'Track Order')),
                ),
              ),
            ],
            if (isCompleted) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAr ? 'تم التوصيل بنجاح' : 'Delivered Successfully',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: isDark ? Colors.white : Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: [
                Tab(text: isAr ? 'الطلبات الحالية' : 'Current Orders'),
                Tab(text: isAr ? 'الطلبات السابقة' : 'Previous Orders'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Current Orders
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildOrderCard(
                      orderId: '1020',
                      time: isAr ? 'قيد التوصيل' : 'In Transit',
                      from: isAr ? 'مغسلة النور' : 'Al Noor Laundry',
                      to: isAr ? 'منطقة المارينا' : 'Marina Area',
                    ),
                  ],
                ),
                // Previous Orders
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildOrderCard(
                      orderId: '985',
                      time: isAr ? 'أمس 04:30 م' : 'Yesterday 04:30 PM',
                      from: isAr ? 'مغسلة الرمال' : 'Al Rimal Laundry',
                      to: isAr ? 'جميرا' : 'Jumeirah',
                      isCompleted: true,
                    ),
                    _buildOrderCard(
                      orderId: '972',
                      time: '2026-05-01',
                      from: isAr ? 'المغسلة الذهبية' : 'Golden Laundry',
                      to: isAr ? 'الشارقة' : 'Sharjah',
                      isCompleted: true,
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
      padding: const EdgeInsets.all(20),
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
                  border: Border.all(color: theme.colorScheme.primary, width: 2),
                ),
                child: Icon(Icons.person, size: 60, color: isDark ? Colors.white : theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                _userName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
        _buildProfileItem(Icons.phone_outlined, isAr ? 'رقم الهاتف' : 'Phone Number', _userPhone),
        _buildProfileItem(Icons.email_outlined, isAr ? 'البريد الإلكتروني' : 'Email Address', 'driver@brightclean.com'),
        _buildProfileItem(Icons.drive_eta_outlined, isAr ? 'نوع المركبة' : 'Vehicle Type', isAr ? 'سيارة صالون' : 'Sedan Car'),
        _buildProfileItem(Icons.confirmation_number_outlined, isAr ? 'رقم اللوحة' : 'Plate Number', 'A 12345'),
        
        const SizedBox(height: 32),
        
        // Logout Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: Text(isAr ? 'تسجيل الخروج' : 'Logout', style: const TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        content: Text(isAr ? 'هل أنت متأكد أنك تريد تسجيل الخروج؟' : 'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Clear all data on logout
              if (mounted) {
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
        flexibleSpace: SafeArea(
          child: Stack(
            children: [
              // Icons forced to the left using Directionality(LTR)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      ValueListenableBuilder<Locale>(
                        valueListenable: LanguageController().locale,
                        builder: (context, locale, _) {
                          return TextButton(
                            onPressed: () {
                              LanguageController().toggleLanguage();
                              _loadUserData();
                            },
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero, 
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              locale.languageCode == 'ar' ? 'EN' : 'عربي',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: ThemeController().themeMode,
                        builder: (context, themeMode, _) {
                          return IconButton(
                            icon: Icon(
                              isDark ? Icons.light_mode : Icons.dark_mode, 
                              color: Colors.white, 
                              size: 22
                            ),
                            onPressed: () => ThemeController().toggleTheme(),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(10),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Centered Title
              Center(
                child: Text(
                  isAr ? 'برايت كلين' : 'Bright Clean',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900, 
                    color: Colors.white, 
                    letterSpacing: 1.2,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
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
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
              label: isAr ? 'الملف' : 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}


