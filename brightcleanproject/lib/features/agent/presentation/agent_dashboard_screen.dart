import 'package:flutter/material.dart';
import 'package:brightcleanproject/core/theme/app_spacing.dart';

import 'package:brightcleanproject/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:brightcleanproject/core/enums/laundry_type.dart';
import 'package:brightcleanproject/core/enums/order_status.dart';
import 'package:brightcleanproject/core/controllers/language_controller.dart';
import 'package:brightcleanproject/core/controllers/theme_controller.dart';
import 'package:provider/provider.dart';
import '../../auth/data/providers/auth_provider.dart';
import '../../customer/data/providers/cart_provider.dart';

// --- (Mock) نموذج بيانات الطلب ---
class AgentOrderModel {
  final String id;
  final LaundryType laundryType;
  final List<String> services;
  OrderStatus status;
  final String customerLocation;
  final String time;
  final String customerName;
  final List<OrderItemMock> items;
  final String notes;

  AgentOrderModel({
    required this.id,
    required this.laundryType,
    required this.services,
    required this.status,
    required this.customerLocation,
    required this.time,
    required this.customerName,
    required this.items,
    required this.notes,
  });
}

class OrderItemMock {
  final String itemName;
  final String serviceType;
  final int quantity;
  final IconData icon;

  OrderItemMock(this.itemName, this.serviceType, this.quantity, this.icon);
}

class AgentDashboardScreen extends StatefulWidget {
  final LaundryType laundryType;

  const AgentDashboardScreen({
    super.key,
    this.laundryType = LaundryType.clothes, 
  });

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  late List<AgentOrderModel> _allOrders;
  bool _isLaundryOpen = true; 
  int _selectedIndex = 0;

  // Settings State
  bool _notifyOrders = true;
  bool _notifyPromotions = false;
  bool _notifySystem = true;
  
  final TextEditingController _nameController = TextEditingController(text: 'مغسلة الخليج');
  final TextEditingController _phoneController = TextEditingController(text: '+966 50 123 4567');
  final TextEditingController _emailController = TextEditingController(text: 'laundry@example.com');

  @override
  void initState() {
    super.initState();
    _allOrders = [
      AgentOrderModel(
        id: '1025',
        laundryType: LaundryType.clothes,
        services: ['غسيل', 'كوي'],
        status: OrderStatus.received,
        customerLocation: 'شارع الشيخ زايد',
        time: 'الآن',
        customerName: 'أحمد محمد',
        items: [
          OrderItemMock('ثوب', 'كوي', 5, Icons.iron),
          OrderItemMock('تيشيرت', 'غسيل', 3, Icons.local_laundry_service),
        ],
        notes: 'ملاحظة: القطع تحتاج عناية خاصة للملابس الحساسة',
      ),
      AgentOrderModel(
        id: '1026',
        laundryType: LaundryType.clothes,
        services: ['تنظيف جاف'],
        status: OrderStatus.washing,
        customerLocation: 'حي الملك فهد',
        time: 'منذ ساعتين',
        customerName: 'فاطمة علي',
        items: [
          OrderItemMock('فستان', 'تنظيف جاف', 2, Icons.dry_cleaning),
        ],
        notes: 'يرجى الحفاظ على نوعية القماش',
      ),
      AgentOrderModel(
        id: '1027',
        laundryType: LaundryType.clothes,
        services: ['كوي'],
        status: OrderStatus.completed,
        customerLocation: 'البرشاء',
        time: 'أمس',
        customerName: 'سعيد خالد',
        items: [
          OrderItemMock('قميص', 'كوي', 10, Icons.iron),
        ],
        notes: 'طلب عادي بدون ملاحظات خاصة',
      ),
      AgentOrderModel(
        id: '2001',
        laundryType: LaundryType.carsBikes,
        services: ['غسيل خارجي', 'تلميع'],
        status: OrderStatus.received,
        customerLocation: 'حي العليا',
        time: 'الآن',
        customerName: 'محمد عبدالله',
        items: [
          OrderItemMock('سيارة', 'غسيل وتلميع', 1, Icons.car_rental),
        ],
        notes: 'سيارة فاخرة - عناية خاصة',
      ),
      AgentOrderModel(
        id: '3001',
        laundryType: LaundryType.carpets,
        services: ['غسيل سجاد', 'تعطير'],
        status: OrderStatus.ready,
        customerLocation: 'حي الملقا',
        time: 'أمس',
        customerName: 'عمر حسن',
        items: [
          OrderItemMock('سجاد', 'غسيل عميق', 3, Icons.texture),
        ],
        notes: 'سجاد فارسي - يحتاج عناية',
      ),
      AgentOrderModel(
        id: '4001',
        laundryType: LaundryType.ac,
        services: ['تنظيف فلاتر', 'تعبئة فريون'],
        status: OrderStatus.ironing,
        customerLocation: 'حي النرجس',
        time: 'منذ ساعة',
        customerName: 'ياسر إبراهيم',
        items: [
          OrderItemMock('مكيف', 'تنظيف كامل', 2, Icons.ac_unit),
        ],
        notes: 'مكيفات سبليت - فحص شامل',
      ),
    ];
  }

  List<AgentOrderModel> get _currentOrders => 
      _allOrders.where((o) => o.laundryType == widget.laundryType && o.status != OrderStatus.completed).toList();

  List<AgentOrderModel> get _previousOrders =>
      _allOrders.where((o) => o.laundryType == widget.laundryType && (o.status == OrderStatus.completed || o.status == OrderStatus.ready)).toList();

  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
            const SizedBox(height: AppSpacing.sm),
            Text(count, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    final isArabic = LanguageController().isArabic;
    List<String> services = [];
    switch (widget.laundryType) {
      case LaundryType.clothes: services = isArabic ? ['غسيل', 'كوي', 'تنظيف جاف', 'غسيل مستعجل'] : ['Wash', 'Iron', 'Dry Clean', 'Express']; break;
      case LaundryType.carsBikes: services = isArabic ? ['غسيل خارجي', 'غسيل داخلي', 'تلميع', 'غسيل مكينة'] : ['Exterior', 'Interior', 'Polishing', 'Engine']; break;
      case LaundryType.carpets: services = isArabic ? ['غسيل عميق', 'تعطير', 'إزالة بقع صعبه'] : ['Deep Wash', 'Scenting', 'Stain Removal']; break;
      case LaundryType.ac: services = isArabic ? ['تنظيف فلاتر', 'غسيل الوحدة الخارجية', 'تعبئة فريون'] : ['Filters', 'Outdoor Unit', 'Gas Refill']; break;
      case LaundryType.tanks: services = isArabic ? ['تفريغ وتنظيف', 'تعقيم الأسطح', 'عزل وتسكير'] : ['Emptying', 'Sterilization', 'Insulation']; break;
      case LaundryType.solarPanels: services = isArabic ? ['تنظيف جاف', 'غسيل بالمواصفات', 'فحص كفاءة'] : ['Dry Clean', 'Spec Wash', 'Efficiency Check']; break;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star_outline, size: 20, color: AppColors.tertiary),
            const SizedBox(width: AppSpacing.xs),
            Text(isArabic ? 'الخدمات التي تقدمها' : 'Your Services', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: services.map((s) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white10 : AppColors.primary.withValues(alpha: 0.1)),
                ),
                child: Text(s, style: TextStyle(color: isDark ? Colors.white : AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderRequestCard(BuildContext context, AgentOrderModel order, bool isArabic, {bool isReadOnly = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 20, offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.primary.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text((isArabic ? 'طلب #' : 'Order #') + order.id, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    isArabic ? order.time : order.time.replaceAll('الآن', 'Now').replaceAll('منذ ساعتين', '2h ago').replaceAll('أمس', 'Yesterday').replaceAll('منذ ساعة', '1h ago'), 
                    style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 12)
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isArabic ? 'الخدمات المطلوبة' : 'Requested Services', style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: order.services.map((service) {
                    IconData icon;
                    final s = service.toLowerCase();
                    if (s.contains('كوي') || s.contains('iron')) {
                      icon = Icons.iron;
                    } else if (s.contains('غسيل') || s.contains('wash')) {
                      icon = Icons.local_laundry_service;
                    } else if (s.contains('تنظيف جاف') || s.contains('dry clean')) {
                      icon = Icons.dry_cleaning;
                    } else if (s.contains('تلميع') || s.contains('polish')) {
                      icon = Icons.auto_fix_high;
                    } else if (s.contains('تعطير') || s.contains('scent')) {
                      icon = Icons.spa; 
                    } else {
                      icon = Icons.cleaning_services;
                    }
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: isDark ? AppColors.lightBlue : AppColors.tertiary),
                          const SizedBox(width: AppSpacing.xs),
                          Text(isArabic ? service : _translateService(service), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(height: 1, thickness: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 18, color: isDark ? AppColors.lightBlue : AppColors.tertiary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          isArabic ? order.customerLocation : _translateLocation(order.customerLocation), 
                          style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: order.status.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(30)),
                      child: Text(isArabic ? order.status.title : order.status.englishTitle, style: TextStyle(color: order.status.color, fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: () async {
                    final newStatus = await context.push<OrderStatus>(
                      '/agent_order_management/${order.id}',
                      extra: {
                        'status': order.status,
                        'isReadOnly': isReadOnly,
                        'order': order,
                      },
                    );
                    if (newStatus != null && !isReadOnly) {
                      setState(() {
                        order.status = newStatus;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isReadOnly ? (isDark ? Colors.white10 : Colors.grey.shade100) : AppColors.primary,
                    foregroundColor: isReadOnly ? (isDark ? Colors.white : Colors.black87) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: isReadOnly ? 0 : 2,
                  ),
                  child: Center(
                    child: Text(
                      isReadOnly ? (isArabic ? 'عرض التفاصيل' : 'View Details') : (isArabic ? 'إدارة الطلب' : 'Manage Order'), 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeSection(List<AgentOrderModel> orders) {
    final isArabic = LanguageController().isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isArabic ? 'مرحباً بك مجدداً!' : 'Welcome Back!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: isDark ? Colors.white : null)),
          Text(isArabic ? 'إليك ملخص نشاطك اليوم' : 'Here is your activity summary', style: TextStyle(fontSize: 14, color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade600)),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _buildStatCard(isArabic ? 'طلبات استلمت' : 'Received', orders.where((o) => o.status == OrderStatus.received).length.toString(), AppColors.primary, Icons.download_rounded),
              const SizedBox(width: AppSpacing.sm),
              _buildStatCard(isArabic ? 'قيد التنفيذ' : 'In Progress', orders.where((o) => o.status == OrderStatus.washing || o.status == OrderStatus.ironing).length.toString(), AppColors.tertiary, Icons.sync_rounded),
              const SizedBox(width: AppSpacing.sm),
              _buildStatCard(isArabic ? 'مكتمل' : 'Completed', _allOrders.where((o) => o.laundryType == widget.laundryType && (o.status == OrderStatus.ready || o.status == OrderStatus.completed)).length.toString(), AppColors.success, Icons.check_circle_rounded),
            ],
          ),
          const SizedBox(height: 32),
          _buildServicesSection(),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isArabic ? 'الطلبات الجارية' : 'Current Orders', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              TextButton(onPressed: () {}, child: Text(isArabic ? 'عرض الكل' : 'View All')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (orders.isEmpty) _buildEmptyState(isArabic ? 'لا توجد طلبات جارية حالياً' : 'No current orders')
          else ...orders.map((order) => _buildOrderRequestCard(context, order, isArabic)),
        ],
      ),
    );
  }

  Widget _buildOrdersSection() {
    final isArabic = LanguageController().isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orders = _previousOrders;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isArabic ? 'سجل الطلبات' : 'Order History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : null)),
          Text(isArabic ? 'مراجعة كافة الطلبات السابقة' : 'Review all previous orders', style: TextStyle(fontSize: 14, color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade600)),
          const SizedBox(height: AppSpacing.xl),
          if (orders.isEmpty) _buildEmptyState(isArabic ? 'سجل الطلبات فارغ' : 'Order history is empty')
          else ...orders.map((order) => _buildOrderRequestCard(context, order, isArabic, isReadOnly: true)),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    final langController = LanguageController();
    final isArabic = langController.isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // حسابي
        _buildSettingsHeader(isArabic ? 'حسابي' : 'My Account'),
        _buildSettingsTile(Icons.person_outline, isArabic ? 'الاسم' : 'Name', _nameController.text, onTap: () => _showEditDialog(isArabic ? 'الاسم' : 'Name', _nameController)),
        _buildSettingsTile(Icons.phone_outlined, isArabic ? 'رقم الهاتف' : 'Phone Number', _phoneController.text, onTap: () => _showEditDialog(isArabic ? 'رقم الهاتف' : 'Phone Number', _phoneController)),
        _buildSettingsTile(Icons.email_outlined, isArabic ? 'البريد الإلكتروني' : 'Email', _emailController.text, onTap: () => _showEditDialog(isArabic ? 'البريد الإلكتروني' : 'Email', _emailController)),
        _buildSwitchTile(
          isArabic
            ? (_isLaundryOpen ? 'حالة المغسلة (مفتوح)' : 'حالة المغسلة (مغلق)')
            : (_isLaundryOpen ? 'Laundry Status (Open)' : 'Laundry Status (Closed)'),
          _isLaundryOpen,
          (v) => setState(() => _isLaundryOpen = v),
          icon: Icons.store_outlined,
        ),
        
        const SizedBox(height: AppSpacing.xl),
        
        // التنبيهات
        _buildSettingsHeader(isArabic ? 'إعدادات التنبيهات' : 'Notification Settings'),
        _buildSwitchTile(isArabic ? 'تنبيهات الطلبات الجديدة' : 'New Order Alerts', _notifyOrders, (v) => setState(() => _notifyOrders = v)),
        _buildSwitchTile(isArabic ? 'العروض الترويجية' : 'Promotions', _notifyPromotions, (v) => setState(() => _notifyPromotions = v)),
        _buildSwitchTile(isArabic ? 'تنبيهات النظام' : 'System Alerts', _notifySystem, (v) => setState(() => _notifySystem = v)),
        
        const SizedBox(height: AppSpacing.xl),
        
        // التفضيلات
        _buildSettingsHeader(isArabic ? 'التفضيلات' : 'Preferences'),
        ListTile(
          leading: Icon(Icons.language, color: isDark ? Colors.white : AppColors.primary),
          title: Text(isArabic ? 'لغة التطبيق' : 'App Language', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : null)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isArabic ? 'العربية' : 'English', 
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.primary, 
                fontWeight: FontWeight.bold
              )
            ),
          ),
          onTap: () {
            setState(() {
              langController.toggleLanguage();
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
              isArabic ? 'الوضع الليلي' : 'Night Mode',
              isDarkTheme,
              (_) => ThemeController().toggleTheme(),
              icon: isDarkTheme ? Icons.dark_mode : Icons.light_mode,
            );
          },
        ),
        
        const Divider(height: 40),
        _buildSettingsTile(
          Icons.logout,
          isArabic ? 'تسجيل الخروج' : 'Logout',
          isArabic ? 'تسجيل خروج من الحساب' : 'Logout from account',
          color: AppColors.error,
          onTap: _showLogoutDialog,
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog() async {
    final isArabic = LanguageController().isArabic;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final t = Theme.of(ctx);
        return AlertDialog(
          title: Text(isArabic ? 'تسجيل الخروج' : 'Logout', style: TextStyle(color: t.colorScheme.error)),
          content: Text(isArabic ? 'هل أنت متأكد أنك تريد تسجيل الخروج؟' : 'Are you sure you want to logout?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(isArabic ? 'إلغاء' : 'Cancel', style: TextStyle(color: t.colorScheme.onSurface.withValues(alpha: 0.6))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: t.colorScheme.error, foregroundColor: t.colorScheme.onError),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(isArabic ? 'تأكيد' : 'Confirm'),
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

  Widget _buildSettingsHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: TextStyle(fontSize: 14, color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade600, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged, {IconData? icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SwitchListTile(
      secondary: Icon(
        icon ?? (value ? Icons.notifications_active : Icons.notifications_off), 
        color: value 
            ? (isDark ? Colors.white : AppColors.primary) 
            : (isDark ? Colors.white38 : Colors.grey)
      ),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : null)),
      value: value,
      onChanged: onChanged,
      activeTrackColor: isDark ? Colors.white30 : AppColors.primary.withValues(alpha: 0.5),
      activeThumbColor: isDark ? Colors.white : AppColors.primary,
    );
  }

  void _showEditDialog(String title, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'أدخل $title الجديد'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () {
            setState(() {});
            Navigator.pop(context);
          }, child: const Text('حفظ')),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, {Color? color, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: color ?? (isDark ? Colors.white : AppColors.primary)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? (isDark ? Colors.white : null))),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : null)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.white70 : null),
      onTap: onTap,
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }


  String _translateService(String service) {
    final Map<String, String> translations = {
      'غسيل': 'Wash',
      'كوي': 'Iron',
      'تنظيف جاف': 'Dry Clean',
      'غسيل مستعجل': 'Express Wash',
      'غسيل خارجي': 'Exterior Wash',
      'غسيل داخلي': 'Interior Wash',
      'تلميع': 'Polishing',
      'غسيل مكينة': 'Engine Wash',
      'غسيل عميق': 'Deep Wash',
      'تعطير': 'Scenting',
      'إزالة بقع صعبه': 'Stain Removal',
      'تنظيف فلاتر': 'Filters Cleaning',
      'غسيل الوحدة الخارجية': 'Outdoor Unit Wash',
      'تعبئة فريون': 'Gas Refill',
      'تفريغ وتنظيف': 'Emptying & Cleaning',
      'تعقيم الأسطح': 'Surface Sterilization',
      'عزل وتسكير': 'Insulation',
      'غسيل بالمواصفات': 'Spec Wash',
      'فحص كفاءة': 'Efficiency Check',
      'ثوب': 'Thoob',
      'ثياب': 'Clothes',
      'ملابس': 'Clothes',
    };

    String translated = service;
    translations.forEach((ar, en) {
      if (translated.contains(ar)) {
        translated = translated.replaceAll(ar, en);
      }
    });
    return translated;
  }

  String _translateLocation(String location) {
    final Map<String, String> translations = {
      'شارع الشيخ زايد': 'Sheikh Zayed Rd',
      'حي الملك فهد': 'King Fahd District',
      'البرشاء': 'Al Barsha',
      'حي العليا': 'Al Olaya',
      'حي الملقا': 'Al Malqa',
      'حي النرجس': 'Al Narjis',
      'دبي': 'Dubai',
      'الرياض': 'Riyadh',
    };

    String translated = location;
    translations.forEach((ar, en) {
      if (translated.contains(ar)) {
        translated = translated.replaceAll(ar, en);
      }
    });
    return translated;
  }

  @override
  Widget build(BuildContext context) {
    final langController = LanguageController();
    
    return ValueListenableBuilder<Locale>(
      valueListenable: langController.locale,
      builder: (context, locale, _) {
        final isArabic = locale.languageCode == 'ar';
        
        return Scaffold(
          appBar: AppBar(
            title: Text(_selectedIndex == 0 
                ? _nameController.text 
                : _selectedIndex == 1 
                    ? (isArabic ? 'الطلبات' : 'Orders') 
                    : (isArabic ? 'حسابي' : 'My Account')),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  context.push('/notifications');
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeSection(_currentOrders),
              _buildOrdersSection(),
              _buildSettingsSection(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: Theme.of(context).brightness == Brightness.dark ? AppColors.lightBlue : AppColors.primary,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home_filled), label: isArabic ? 'الرئيسية' : 'Home'),
              BottomNavigationBarItem(icon: const Icon(Icons.history), label: isArabic ? 'الطلبات' : 'Orders'),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: isArabic ? 'حسابي' : 'My Account',
              ),
            ],
          ),
        );
      }
    );
  }
}
