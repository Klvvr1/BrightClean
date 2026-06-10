import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../core/enums/service_activation_status.dart';
import '../data/providers/admin_provider.dart';
import '../data/models/admin_service_model.dart';
import '../data/models/activation_request_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/controllers/system_status_provider.dart';
import 'admin_profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  static final List<Map<String, dynamic>> couponsList = [];

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _systemNotificationsEnabled = true;

  String _searchQuery = '';
  String _serviceSearchQuery = '';
  String _laundrySearchQuery = '';
  int? _selectedLaundryAgentId;
  int? _selectedServiceFilterId;
  Set<int> _selectedLaundryServiceIds = {};
  bool _isLoadingLaundryServices = false;
  List<Map<String, dynamic>> get _coupons => AdminDashboardScreen.couponsList;

  static const List<String> _serviceCategoryLabels = [
    'غسيل',
    'مفروشات منزلية',
    'خدمات منزلية',
    'غسيل مركبات',
  ];

  static const List<String> _serviceTypeLabels = [
    'غسيل وكي',
    'تنظيف جاف',
    'كي فقط',
    'ستائر',
    'مفارش',
    'بطانيات',
    'سجاد',
    'تنظيف منزل',
    'تنظيف مكيفات',
    'تنظيف خزانات',
    'تنظيف ألواح شمسية',
    'غسيل سيارة',
    'غسيل دراجة',
  ];

  static const List<String> _pricingModelLabels = [
    'بالقطعة',
    'سعر ثابت',
  ];

  static const List<String> _deliveryModelLabels = [
    'استلام وتوصيل',
    'زيارة فني',
  ];

  late TextEditingController _maintenanceMessageController;

  @override
  void initState() {
    super.initState();
    _maintenanceMessageController =
        TextEditingController(text: 'النظام تحت الصيانة');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<SystemStatusProvider>(context, listen: false);
      final currentMessage =
          provider.maintenanceMessage ?? 'النظام تحت الصيانة';
      _maintenanceMessageController.text = currentMessage;
      context.read<AdminProvider>().fetchSummary();
      context.read<AdminProvider>().fetchPendingUsers();
      context.read<AdminProvider>().fetchApprovedStaff();
      context.read<AdminProvider>().fetchServices();
      context.read<AdminProvider>().fetchServiceActivationRequests();
      context.read<AdminProvider>().fetchRecentOrders();
    });
  }

  @override
  void dispose() {
    _maintenanceMessageController.dispose();
    super.dispose();
  }

  // Dummy data for live orders
  final List<Map<String, dynamic>> _liveOrders = [];

  List<FlSpot> _getRevenueSpots(double totalRevenue) {
    return [
      const FlSpot(0, 0),
      FlSpot(1, totalRevenue),
    ];
  }

  // Dummy data for pending requests
  final List<Map<String, dynamic>> _pendingRequests = [];

  // Dummy data for staff members
  final List<Map<String, dynamic>> _staffMembers = [];

  final List<Map<String, dynamic>> _notificationHistory = [];

  final List<Map<String, dynamic>> _adminActivities = [];

  void _logActivity(String title, String type, IconData icon, Color color) {
    setState(() {
      _adminActivities.insert(0, {
        'title': title,
        'type': type,
        'time': 'الآن',
        'icon': icon,
        'color': color,
      });
    });
  }

  final List<String> _titles = [
    'الرئيسية',
    'إدارة التسجيلات',
    'العروض',
    'حسابي'
  ];
  String get _currentTitle {
    if (_selectedIndex == 2) return 'إدارة الخدمات';
    if (_selectedIndex > 2) return _titles[_selectedIndex - 1];
    return _titles[_selectedIndex];
  }

  void _showWarningDialog(String name) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إرسال تحذير لـ $name'),
        content: CustomTextField(
          hintText: 'اكتب سبب التحذير هنا...',
          maxLines: 3,
          controller: reasonController,
        ),
        actions: [
          TextButton(
            onPressed: () {
              reasonController.dispose();
              Navigator.pop(context);
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text;
              reasonController.dispose();
              Navigator.pop(context);
              _logActivity(
                'تم إرسال تحذير لـ "$name"${reason.isNotEmpty ? " بسبب: $reason" : ""}',
                'warning',
                Icons.warning_amber_rounded,
                AppColors.warning,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'تم إرسال التحذير لـ $name${reason.isNotEmpty ? ": $reason" : ""}')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('إرسال', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _acceptStaff(Map<String, dynamic> request) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    if (adminProvider.isActionLoading) return;
    final userId = request['id'] as int?;
    if (userId != null) {
      try {
        await adminProvider.approveUser(userId);
        if (mounted) {
          _logActivity(
            'تم قبول طلب انضمام ${request['type']} "${request['name']}" وتفعيل الحساب',
            request['type'] == 'مغسلة' ? 'add_laundry' : 'add_driver',
            request['type'] == 'مغسلة' ? Icons.business : Icons.person_add,
            AppColors.success,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم قبول ${request['name']} بنجاح')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  adminProvider.errorMessage ?? 'حدث خطأ أثناء تفعيل الحساب'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _rejectStaff(String name) {
    setState(() {
      _pendingRequests.removeWhere((r) => r['name'] == name);
    });
    _logActivity(
      'تم رفض طلب انضمام "$name"',
      'reject_staff',
      Icons.highlight_off,
      AppColors.error,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم رفض طلب $name')),
    );
  }

  void _dismissStaff(String name, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 28),
            const SizedBox(width: 10),
            const Text(
              'تأكيد طرد من النظام',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.error),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد تماماً من رغبتك في طرد "$name" ($type) من النظام؟\n\nهذا الإجراء سيقوم بإلغاء تفعيل حسابه وإيقاف صلاحية الوصول الخاصة به بالكامل فوراً.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء',
                style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _staffMembers.removeWhere((m) => m['name'] == name);
              });
              _logActivity(
                'تم طرد $type "$name" وإلغاء تفعيل حسابه من النظام',
                type == 'مغسلة' ? 'remove_laundry' : 'remove_driver',
                Icons.person_remove,
                AppColors.error,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم طرد $name ($type) من النظام بنجاح'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('نعم، طرد من النظام',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(double totalRevenue) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppStyles.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الإيرادات المسجلة',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getRevenueSpots(totalRevenue),
                    isCurved: true,
                    color: AppColors.success,
                    barWidth: 4,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.success.withValues(alpha: 0.1),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الطلبات المباشرة',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _liveOrders.length,
            itemBuilder: (context, index) {
              final order = _liveOrders[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(left: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: AppStyles.surface(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('طلب #${order['id']}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(order['status'],
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(order['type'],
                        style: TextStyle(
                            color: AppColors.textLight, fontSize: 12)),
                    Text(order['driver'] ?? order['laundry'] ?? '',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                    Text(order['time'],
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.error)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      {String? subValue, int delay = 0}) {
    final start = max(0.0, delay / 800.0);
    final end = min(1.0, (delay + 500) / 800.0);
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Interval(start, end, curve: Curves.easeOut),
      builder: (context, double opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - opacity)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppStyles.surface(context).copyWith(
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color ??
                    AppColors.textLight,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (subValue != null)
              Text(
                subValue,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection(List<dynamic> recentOrders) {
    if (recentOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppStyles.surface(context),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.receipt_long, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'لا توجد طلبات حديثة',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentOrders.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final order = recentOrders[index] is Map
            ? Map<dynamic, dynamic>.from(recentOrders[index] as Map)
            : <dynamic, dynamic>{};
        final bookingId = AdminServiceModel.readInt(
          order,
          ['bookingID', 'bookingId', 'BookingID'],
        );
        final clientName = AdminServiceModel.readString(
          order,
          ['clientName', 'ClientName'],
          fallback: 'عميل',
        );
        final laundryName = AdminServiceModel.readString(
          order,
          ['laundryName', 'LaundryName'],
          fallback: '',
        );
        final finalTotal = AdminServiceModel.readDouble(
          order,
          ['finalTotal', 'FinalTotal'],
        );
        final status = AdminServiceModel.readString(
          order,
          ['status', 'Status'],
          fallback: '',
        );
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: AppStyles.surface(context),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.receipt_long, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('طلب #$bookingId',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      laundryName.isEmpty
                          ? 'عميل: $clientName'
                          : 'عميل: $clientName • $laundryName',
                      style:
                          TextStyle(color: AppColors.textLight, fontSize: 12),
                    ),
                    if (status.isNotEmpty)
                      Text(
                        status,
                        style:
                            TextStyle(color: AppColors.textLight, fontSize: 11),
                      ),
                  ],
                ),
              ),
              Text(
                finalTotal > 0 ? '${finalTotal.toStringAsFixed(0)} ر.ي' : '-',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.success),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomeView() {
    final adminProvider = context.watch<AdminProvider>();
    final summary = adminProvider.summary;
    final driversCount = summary.driversCount;
    final laundriesCount = summary.laundryAgentsCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نظرة عامة',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildRevenueChart(summary.totalRevenue),
          const SizedBox(height: AppSpacing.xl),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildStatCard('إجمالي الطلبات', '${summary.totalOrders}',
                  Icons.shopping_bag_outlined, AppColors.primary,
                  delay: 0),
              _buildStatCard(
                  'الإيرادات',
                  '${summary.totalRevenue.toStringAsFixed(0)} ر.ي',
                  Icons.account_balance_wallet_outlined,
                  AppColors.success,
                  delay: 100),
              _buildStatCard('عدد العملاء', '${summary.customersCount}',
                  Icons.people_outline, AppColors.secondary,
                  delay: 200),
              _buildStatCard(
                'السائقين',
                '$driversCount',
                Icons.drive_eta_outlined,
                AppColors.tertiary,
                subValue: 'المعتمدين في النظام',
                delay: 300,
              ),
              _buildStatCard(
                'المغاسل',
                '$laundriesCount',
                Icons.local_laundry_service_outlined,
                AppColors.warning,
                subValue: 'المشتركة حالياً',
                delay: 400,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildLiveOrdersSection(),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'الطلبات الأخيرة',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRecentOrdersSection(adminProvider.recentOrders),
          const SizedBox(height: AppSpacing.xl),
          _buildOperationControlPanel(),
          const SizedBox(height: AppSpacing.xl),
          _buildAdminActivitiesSection(),
        ],
      ),
    );
  }

  Widget _buildAdminActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'سجل عمليات المشرف الأخيرة',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
            if (_adminActivities.length > 5)
              TextButton(
                onPressed: _showAllActivitiesBottomSheet,
                child: const Text('عرض الكل',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_adminActivities.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            width: double.infinity,
            decoration: AppStyles.surface(context),
            child: const Center(
              child: Text(
                'لا توجد عمليات مسجلة حالياً',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _adminActivities.take(5).length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final activity = _adminActivities[index];
              return Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: AppStyles.surface(context).copyWith(
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: activity['color'].withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        activity['icon'],
                        color: activity['color'],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity['time'],
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildOperationControlPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'لوحة العمليات والتشغيل',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: AppStyles.surface(context),
          child: Column(
            children: [
              // Maintenance Mode Switch Tile
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color:
                        (!context.watch<SystemStatusProvider>().isLoginEnabled
                                ? AppColors.error
                                : AppColors.primary)
                            .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.settings_suggest,
                    color: !context.watch<SystemStatusProvider>().isLoginEnabled
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                ),
                title: const Text('وضع الصيانة للنظام',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text(
                    'إيقاف استقبال طلبات الغسيل الجديدة ومنع تسجيل الدخول',
                    style: TextStyle(fontSize: 12)),
                trailing: Switch(
                  value: !context.watch<SystemStatusProvider>().isLoginEnabled,
                  onChanged: (v) async {
                    try {
                      final message = v
                          ? (_maintenanceMessageController.text.isNotEmpty
                              ? _maintenanceMessageController.text
                              : "النظام تحت الصيانة")
                          : null;
                      await context
                          .read<AdminProvider>()
                          .toggleSystemStatus(!v, message);
                      if (!mounted) return;
                      await context.read<SystemStatusProvider>().checkStatus();
                      _logActivity(
                        v
                            ? 'تم تفعيل وضع صيانة النظام'
                            : 'تم إلغاء وضع صيانة النظام',
                        v ? 'error' : 'success',
                        Icons.settings_suggest,
                        v ? AppColors.error : AppColors.success,
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('حدث خطأ: $e')),
                        );
                      }
                    }
                  },
                  activeThumbColor: AppColors.error,
                ),
              ),
              if (!context.watch<SystemStatusProvider>().isLoginEnabled) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: AppColors.error, size: 20),
                          SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'تنبيه: تطبيق العملاء متوقف حالياً ولا يمكنهم تقديم طلبات.',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CustomTextField(
                        controller: _maintenanceMessageController,
                        hintText: 'رسالة الصيانة التي ستظهر للعملاء...',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await context
                                  .read<AdminProvider>()
                                  .toggleSystemStatus(
                                    false,
                                    _maintenanceMessageController.text,
                                  );
                              if (!mounted) return;
                              await context
                                  .read<SystemStatusProvider>()
                                  .checkStatus();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('تم حفظ رسالة الصيانة بنجاح!')),
                              );
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('حدث خطأ: $e')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('حفظ ونشر الرسالة للعملاء',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(height: 24),
              // System Notifications Switch Tile
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text('إشعارات النظام الذكية',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text(
                    'تنبيهات فورية للمشرف عن المشاكل التقنية والشكاوى',
                    style: TextStyle(fontSize: 12)),
                trailing: Switch(
                  value: _systemNotificationsEnabled,
                  onChanged: (v) {
                    setState(() {
                      _systemNotificationsEnabled = v;
                    });
                    _logActivity(
                      v
                          ? 'تم تفعيل إشعارات النظام الذكية'
                          : 'تم تعطيل إشعارات النظام الذكية',
                      'info',
                      Icons.notifications_active_outlined,
                      AppColors.primary,
                    );
                  },
                  activeThumbColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAllActivitiesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'سجل عمليات المشرف الكامل',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.error),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 30),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: _adminActivities.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final activity = _adminActivities[index];
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: activity['color'].withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            activity['icon'],
                            color: activity['color'],
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activity['time'],
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationsView() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'طلبات التوظيف'),
              Tab(text: 'إدارة الموظفين'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPendingRegistrations(),
                _buildApprovedStaff(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRegistrations() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (adminProvider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                adminProvider.errorMessage!,
                style: const TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final List<Map<String, dynamic>> mappedPending =
            adminProvider.pendingUsers.map((u) {
          final isLaundry = u.role.toLowerCase() == 'laundryagent';
          String? documentUrl(String type) {
            for (final document in u.documents) {
              if (document.type.toLowerCase() == type.toLowerCase() &&
                  document.fileUrl.isNotEmpty) {
                return document.fileUrl;
              }
            }
            return null;
          }

          return {
            'id': u.id,
            'name': isLaundry
                ? (u.businessName ?? '${u.firstName} ${u.lastName}')
                : '${u.firstName} ${u.lastName}',
            'managerName': '${u.firstName} ${u.lastName}',
            'type': isLaundry ? 'مغسلة' : 'سائق',
            'phone': u.phoneNo ?? 'غير متوفر',
            'email': u.email,
            'location': 'غير متوفر',
            'commercialRegister': u.commercialRegister ?? 'غير متوفر',
            'nationalId': u.nationalIdNumber ?? 'غير متوفر',
            'licenseNumber': 'غير متوفر',
            'vehicleType': u.vehicleType ?? 'غير متوفر',
            'vehiclePlate': u.plateNumber ?? 'غير متوفر',
            'commercialRegisterImage': documentUrl('CommercialRegistration'),
            'nationalIdImage': documentUrl('NationalID'),
            'storefrontImage': null,
            'licenseImage': documentUrl('DriverLicense'),
            'vehicleImage': documentUrl('VehicleImage'),
          };
        }).toList();

        final laundries =
            mappedPending.where((r) => r['type'] == 'مغسلة').toList();
        final drivers =
            mappedPending.where((r) => r['type'] == 'سائق').toList();

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildSectionHeader('المغاسل'),
            if (laundries.isEmpty)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('لا توجد طلبات مغاسل حالياً'))),
            ...laundries.map((r) => _buildRegistrationItem(r)),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionHeader('السائقين'),
            if (drivers.isEmpty)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('لا توجد طلبات مناديب حالياً'))),
            ...drivers.map((r) => _buildRegistrationItem(r)),
          ],
        );
      },
    );
  }

  void _showStaffDetails(Map<String, dynamic> staff) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(
                    staff['type'] == 'مغسلة'
                        ? Icons.local_laundry_service
                        : _getVehicleIcon(staff['vehicleType'], staff['name']),
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(staff['name'],
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(staff['type'],
                          style: TextStyle(color: AppColors.textLight)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star,
                          color: AppColors.warning, size: 18),
                      const SizedBox(width: 4),
                      Text('${staff['rating']}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 40),
            const Text('المعلومات الشخصية والمهنية',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  if (staff['type'] == 'مغسلة') ...[
                    _buildDetailRow(
                        Icons.business, 'اسم المغسلة', staff['name']),
                    _buildDetailRow(Icons.person, 'اسم المدير المسؤول',
                        staff['managerName'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.phone, 'رقم الهاتف', staff['phone']),
                    _buildDetailRow(Icons.email, 'البريد الإلكتروني',
                        staff['email'] ?? 'غير متوفر'),
                    _buildDetailRow(
                        Icons.location_on, 'الموقع', staff['location']),
                    _buildDetailRow(Icons.badge, 'رقم الهوية الوطنية للمدير',
                        staff['nationalId'] ?? 'غير متوفر'),
                    _buildDetailRow(
                        Icons.assignment,
                        'رقم السجل التجاري / الترخيص',
                        staff['commercialRegister'] ?? 'غير متوفر'),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'المستندات والوثائق المرفوعة',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildDocumentRow('صورة السجل التجاري / الترخيص',
                        staff['commercialRegisterImage']),
                    _buildDocumentRow(
                        'صورة الهوية الوطنية للمدير', staff['nationalIdImage']),
                    _buildDocumentRow(
                        'صورة واجهة/لوحة المغسلة', staff['storefrontImage']),
                  ] else ...[
                    _buildDetailRow(Icons.person, 'اسم المندوب', staff['name']),
                    _buildDetailRow(Icons.phone, 'رقم الهاتف', staff['phone']),
                    _buildDetailRow(Icons.email, 'البريد الإلكتروني',
                        staff['email'] ?? 'غير متوفر'),
                    _buildDetailRow(
                        Icons.location_on, 'الموقع', staff['location']),
                    _buildDetailRow(Icons.badge, 'رقم الهوية الوطنية',
                        staff['nationalId'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.card_membership, 'رقم رخصة القيادة',
                        staff['licenseNumber'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.directions_car, 'نوع مركبة التوصيل',
                        staff['vehicleType'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.tag, 'رقم لوحة المركبة',
                        staff['vehiclePlate'] ?? 'غير متوفر'),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'المستندات والوثائق المرفوعة',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildDocumentRow(
                        'صورة رخصة القيادة للمندوب', staff['licenseImage']),
                    _buildDocumentRow('صورة الهوية الوطنية للمندوب',
                        staff['nationalIdImage']),
                    _buildDocumentRow(
                        'صورة المركبة الخاصة بالتوصيل', staff['vehicleImage']),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  const Text('الطلبات الحالية/السابقة',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  const SizedBox(height: AppSpacing.sm),
                  if (staff['orders'] == null || staff['orders'].isEmpty)
                    const Text('لا توجد طلبات مسجلة حالياً',
                        style: TextStyle(color: AppColors.textLight))
                  else
                    ...staff['orders']
                        .map<Widget>((order) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.receipt_long,
                                  color: AppColors.tertiary),
                              title: Text(order),
                            ))
                        .toList(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('جاري فتح الخريطة...')),
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('مشاهدة الموقع'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _dismissStaff(staff['name'], staff['type']);
                    },
                    icon: const Icon(Icons.person_remove),
                    label: const Text('طرد الموظف'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textLight, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text('$label: ', style: TextStyle(color: AppColors.textLight)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(String label, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            const Icon(Icons.broken_image, color: Colors.grey, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text('$label: ', style: TextStyle(color: AppColors.textLight)),
            const Text('غير متوفر', style: TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    final resolvedImageUrl = imageUrl.startsWith('http')
        ? imageUrl
        : '${BaseApiClient.defaultBaseUrl}$imageUrl';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            resolvedImageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 50,
              height: 50,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image_not_supported, size: 20),
            ),
          ),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: const Text(
          'انقر للمعاينة والتكبير',
          style: TextStyle(fontSize: 11, color: AppColors.primary),
        ),
        trailing: const Icon(Icons.fullscreen, color: AppColors.primary),
        onTap: () => _showImagePreviewDialog(label, resolvedImageUrl),
      ),
    );
  }

  void _showImagePreviewDialog(String title, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: Container(
          decoration: AppStyles.surface(context),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.error),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  width: double.infinity,
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(AppSpacing.lg),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                        child: Icon(Icons.image_not_supported,
                            size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'استخدم إصبعين للتكبير والتحريك 🔎',
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovedStaff() {
    final adminProvider = context.watch<AdminProvider>();
    final approvedStaff = _mapApprovedStaff(adminProvider.approvedStaff);
    final filteredStaff = approvedStaff.where((staff) {
      final name = staff['name'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'بحث عن مغسلة أو مندوب...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildSectionHeader('المغاسل المعتمدة'),
              ...filteredStaff.where((s) => s['type'] == 'مغسلة').map((s) =>
                  _buildStaffItem(s['name'], s['type'], s['rating'],
                      staffData: s)),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionHeader('السائقين المعتمدين'),
              ...filteredStaff.where((s) => s['type'] == 'سائق').map((s) =>
                  _buildStaffItem(s['name'], s['type'], s['rating'],
                      staffData: s)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLaundryFirstServicesView() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final services = adminProvider.services;
        final filteredServices = services.where((service) {
          final query = _serviceSearchQuery.toLowerCase();
          return service.serviceName.toLowerCase().contains(query) ||
              _serviceLabel(_serviceCategoryLabels, service.category)
                  .contains(query) ||
              _serviceLabel(_serviceTypeLabels, service.type).contains(query);
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            final provider = context.read<AdminProvider>();
            await provider.fetchServices();
            await provider.fetchServiceActivationRequests();
            await provider.fetchApprovedStaff();
            if (_selectedLaundryAgentId != null) {
              await _loadLaundryServices(_selectedLaundryAgentId);
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'إدارة الخدمات',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: adminProvider.isActionLoading
                        ? null
                        : () => _showServiceFormDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('إضافة خدمة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (adminProvider.isLoading && services.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (adminProvider.errorMessage != null && services.isEmpty)
                _buildServicesError(adminProvider.errorMessage!)
              else ...[
                _buildServiceActivationRequestsSection(adminProvider),
                const SizedBox(height: AppSpacing.lg),
                _buildLaundryAgentsSection(adminProvider),
                const SizedBox(height: AppSpacing.lg),
                _buildSelectedLaundryServicesEditor(adminProvider),
                const SizedBox(height: AppSpacing.lg),
                _buildServiceFilter(adminProvider),
                const SizedBox(height: AppSpacing.lg),
                _buildCatalogManagementSection(filteredServices),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceActivationRequestsSection(AdminProvider adminProvider) {
    final requests = adminProvider.serviceActivationRequests;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppStyles.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'طلبات تعديل خدمات المغاسل',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'تحديث',
                onPressed: adminProvider.isLoading
                    ? null
                    : adminProvider.fetchServiceActivationRequests,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (requests.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
              child: const Text(
                'لا توجد طلبات تعديل خدمات حالياً',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...requests.map(
              (request) => _buildServiceActivationRequestTile(
                adminProvider,
                request,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceActivationRequestTile(
    AdminProvider adminProvider,
    ActivationRequestModel request,
  ) {
    final isActivation =
        request.requestType == ActivationRequestType.activation;
    final actionText = isActivation ? 'تفعيل' : 'إلغاء تفعيل';
    final actionColor = isActivation ? AppColors.success : AppColors.warning;
    final isBusy = adminProvider.isActionLoading;

    return InkWell(
      onTap: () => _showServiceActivationRequestDetails(request),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.serviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.agentName,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: actionColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'طلب $actionText',
                          style: TextStyle(
                            color: actionColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Text(
                        'اضغط لعرض التفاصيل',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: isBusy
                  ? null
                  : () => _rejectServiceActivationRequest(request),
              child: const Text('رفض'),
            ),
            const SizedBox(width: AppSpacing.xs),
            ElevatedButton(
              onPressed: isBusy
                  ? null
                  : () => _approveServiceActivationRequest(request),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('قبول'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaundryAgentsSection(AdminProvider adminProvider) {
    final laundries = _serviceAwareLaundryAgents(adminProvider);
    final query = _laundrySearchQuery.trim().toLowerCase();
    final visibleLaundries = laundries.where((laundry) {
      final matchesService = _selectedServiceFilterId == null ||
          _agentServiceIds(laundry).contains(_selectedServiceFilterId);
      final businessName = AdminServiceModel.readString(
        laundry,
        ['businessName', 'BusinessName', 'name'],
        fallback: '',
      ).toLowerCase();
      final matchesSearch = query.isEmpty || businessName.contains(query);
      return matchesService && matchesSearch;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppStyles.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'المغاسل',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'اختر مغسلة لتعديل خدماتها',
            style: TextStyle(color: AppColors.textLight, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            onChanged: (value) => setState(() => _laundrySearchQuery = value),
            decoration: InputDecoration(
              hintText: 'بحث باسم المغسلة...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (visibleLaundries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: Text('لا توجد مغاسل مطابقة للبحث')),
            )
          else
            ...visibleLaundries.map((laundry) {
              final agentId = AdminServiceModel.readInt(
                  laundry, ['id', 'userID', 'userId', 'UserID']);
              final selected = agentId == _selectedLaundryAgentId;
              final serviceIds = _agentServiceIds(laundry);
              final businessName = AdminServiceModel.readString(
                laundry,
                ['businessName', 'BusinessName', 'name'],
                fallback: 'مغسلة #$agentId',
              );
              final storeClosed = AdminServiceModel.readBool(
                  laundry, ['isStoreClosed', 'IsStoreClosed']);
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.08),
                  ),
                ),
                child: ListTile(
                  onTap: agentId == 0
                      ? null
                      : () => _selectLaundryAgent(agentId, serviceIds),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.local_laundry_service,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    businessName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'ID: $agentId • الخدمات: ${serviceIds.length} • الحالة: ${storeClosed ? "مغلقة" : "متاحة"}',
                  ),
                  trailing: selected
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : const Icon(Icons.chevron_left,
                          color: AppColors.textLight),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSelectedLaundryServicesEditor(AdminProvider adminProvider) {
    final assignableServices = adminProvider.services
        .where((service) => service.isAvailable && !service.isDeleted)
        .toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppStyles.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الخدمات التي تقدمها المغسلة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_selectedLaundryAgentId == null)
            const Text('اختر مغسلة من القائمة بالأعلى لتعديل خدماتها')
          else if (_isLoadingLaundryServices)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (assignableServices.isEmpty)
              const Text('لا توجد خدمات مفعلة قابلة للربط حالياً')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: assignableServices.map((service) {
                  final selected =
                      _selectedLaundryServiceIds.contains(service.serviceID);
                  return FilterChip(
                    label: Text(service.serviceName),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        if (selected) {
                          _selectedLaundryServiceIds.remove(service.serviceID);
                        } else {
                          _selectedLaundryServiceIds.add(service.serviceID);
                        }
                      });
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: adminProvider.isActionLoading
                    ? null
                    : () => _saveLaundryServices(),
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ خدمات المغسلة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceFilter(AdminProvider adminProvider) {
    final availableServices = adminProvider.services
        .where((service) => service.isAvailable && !service.isDeleted)
        .toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppStyles.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تصفية حسب الخدمة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<int>(
            initialValue: _selectedServiceFilterId ?? -1,
            decoration: const InputDecoration(
              labelText: 'الخدمة',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int>(
                value: -1,
                child: Text('كل الخدمات'),
              ),
              ...availableServices.map(
                (service) => DropdownMenuItem<int>(
                  value: service.serviceID,
                  child: Text(service.serviceName),
                ),
              ),
            ],
            onChanged: (serviceId) {
              setState(() {
                _selectedServiceFilterId =
                    serviceId == null || serviceId == -1 ? null : serviceId;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogManagementSection(
      List<AdminServiceModel> filteredServices) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      title: const Text(
        'إدارة كتالوج الخدمات',
        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
      subtitle: const Text('إضافة وتعديل وتعطيل وحذف خدمات الكتالوج'),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: TextField(
            onChanged: (v) => setState(() => _serviceSearchQuery = v),
            decoration: InputDecoration(
              hintText: 'بحث عن خدمة...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        _buildServiceCatalogTable(filteredServices),
      ],
    );
  }

  Widget _buildServicesError(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppStyles.surface(context),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 36),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.error, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => context.read<AdminProvider>().fetchServices(),
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCatalogTable(List<AdminServiceModel> services) {
    if (services.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: AppStyles.surface(context),
        child: const Center(child: Text('لا توجد خدمات مطابقة')),
      );
    }

    return Container(
      decoration: AppStyles.surface(context),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('الخدمة')),
            DataColumn(label: Text('التصنيف')),
            DataColumn(label: Text('النوع')),
            DataColumn(label: Text('السعر')),
            DataColumn(label: Text('التسعير')),
            DataColumn(label: Text('التنفيذ')),
            DataColumn(label: Text('الحالة')),
            DataColumn(label: Text('المغاسل')),
            DataColumn(label: Text('إجراءات')),
          ],
          rows: services.map((service) {
            return DataRow(
              cells: [
                DataCell(Text(service.serviceName)),
                DataCell(Text(
                    _serviceLabel(_serviceCategoryLabels, service.category))),
                DataCell(Text(_serviceLabel(_serviceTypeLabels, service.type))),
                DataCell(Text(service.price.toStringAsFixed(2))),
                DataCell(Text(
                    _serviceLabel(_pricingModelLabels, service.pricingModel))),
                DataCell(Text(_serviceLabel(
                    _deliveryModelLabels, service.deliveryModel))),
                DataCell(_buildServiceStatusBadge(service)),
                DataCell(Text(
                    '${service.activeAgentCount}/${service.linkedAgentCount}')),
                DataCell(_buildServiceActions(service)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildServiceStatusBadge(AdminServiceModel service) {
    final text = service.isDeleted
        ? 'محذوفة'
        : service.isAvailable
            ? 'مفعلة'
            : 'معطلة';
    final color = service.isDeleted
        ? AppColors.textLight
        : service.isAvailable
            ? AppColors.success
            : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildServiceActions(AdminServiceModel service) {
    final isBusy = context.watch<AdminProvider>().isActionLoading;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'تعديل',
          onPressed:
              isBusy ? null : () => _showServiceFormDialog(service: service),
          icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
        ),
        IconButton(
          tooltip: service.isAvailable ? 'تعطيل' : 'تفعيل',
          onPressed: isBusy || service.isDeleted
              ? null
              : () => _setServiceAvailability(service, !service.isAvailable),
          icon: Icon(
            service.isAvailable ? Icons.toggle_on : Icons.toggle_off,
            color:
                service.isAvailable ? AppColors.success : AppColors.textLight,
          ),
        ),
        IconButton(
          tooltip: service.isDeleted ? 'استرجاع' : 'حذف',
          onPressed: isBusy
              ? null
              : service.isDeleted
                  ? () => _restoreService(service)
                  : () => _confirmDeleteService(service),
          icon: Icon(
            service.isDeleted ? Icons.restore : Icons.delete_outline,
            color: service.isDeleted ? AppColors.secondary : AppColors.error,
          ),
        ),
      ],
    );
  }

  String _serviceLabel(List<String> labels, int index) {
    if (index >= 0 && index < labels.length) {
      return labels[index];
    }
    return 'غير معروف';
  }

  List<Map<dynamic, dynamic>> _serviceAwareLaundryAgents(
      AdminProvider adminProvider) {
    final serviceAwareAgents = adminProvider.laundryAgentsWithServices
        .whereType<Map>()
        .map((agent) => Map<dynamic, dynamic>.from(agent))
        .toList();
    if (serviceAwareAgents.isNotEmpty) {
      return serviceAwareAgents;
    }

    return _mapApprovedStaff(adminProvider.approvedStaff)
        .where((staff) =>
            staff['type'] == 'مغسلة' || staff['type'] == 'ظ…ط؛ط³ظ„ط©')
        .map((staff) => Map<dynamic, dynamic>.from(staff))
        .toList();
  }

  Set<int> _agentServiceIds(Map<dynamic, dynamic> agent) {
    final rawServiceIds = agent['serviceIds'] ??
        agent['serviceIDs'] ??
        agent['ServiceIds'] ??
        agent['ServiceIDs'];
    if (rawServiceIds is List) {
      return rawServiceIds
          .map((id) => id is int ? id : int.tryParse(id.toString()))
          .whereType<int>()
          .toSet();
    }

    final rawServices = agent['services'] ?? agent['Services'];
    if (rawServices is List) {
      return rawServices
          .whereType<Map>()
          .map((service) =>
              service['serviceID'] ??
              service['serviceId'] ??
              service['ServiceID'])
          .map((id) => id is int ? id : int.tryParse(id.toString()))
          .whereType<int>()
          .toSet();
    }

    return {};
  }

  void _selectLaundryAgent(int agentId, Set<int> currentServiceIds) {
    setState(() {
      _selectedLaundryAgentId = agentId;
      _selectedLaundryServiceIds = currentServiceIds;
    });
    _loadLaundryServices(agentId);
  }

  Future<void> _loadLaundryServices(int? agentId) async {
    setState(() {
      _selectedLaundryAgentId = agentId;
      _selectedLaundryServiceIds = {};
      _isLoadingLaundryServices = agentId != null;
    });

    if (agentId == null) return;

    try {
      final serviceIds =
          await context.read<AdminProvider>().getAgentServiceIds(agentId);
      if (!mounted) return;
      setState(() {
        _selectedLaundryServiceIds = serviceIds.toSet();
        _isLoadingLaundryServices = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingLaundryServices = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل خدمات المغسلة: $e')),
      );
    }
  }

  Future<void> _saveLaundryServices() async {
    final agentId = _selectedLaundryAgentId;
    if (agentId == null) return;
    if (_selectedLaundryServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب اختيار خدمة واحدة على الأقل')),
      );
      return;
    }

    try {
      await context.read<AdminProvider>().setAgentServices(
          agentId, _selectedLaundryServiceIds.toList()..sort());
      if (!mounted) return;
      await _loadLaundryServices(agentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ خدمات المغسلة بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ خدمات المغسلة: $e')),
      );
    }
  }

  Future<void> _showServiceActivationRequestDetails(
      ActivationRequestModel request) async {
    final provider = context.read<AdminProvider>();
    final currentServiceIds =
        await _readRequestAgentServiceIds(provider, request);
    if (!mounted) return;

    final currentServices = provider.services
        .where((service) => currentServiceIds.contains(service.serviceID))
        .toList();
    final isActivation =
        request.requestType == ActivationRequestType.activation;
    final resultingServices = isActivation
        ? {
            ...currentServiceIds,
            request.serviceId,
          }
        : currentServiceIds.where((id) => id != request.serviceId).toSet();
    final resultingServiceNames = provider.services
        .where((service) => resultingServices.contains(service.serviceID))
        .map((service) => service.serviceName)
        .toList();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('تفاصيل طلب تعديل الخدمة'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRequestDetailRow('المغسلة', request.agentName),
                  _buildRequestDetailRow('معرف المغسلة', '${request.agentId}'),
                  const Divider(height: 24),
                  const Text(
                    'الخدمات الحالية',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildServiceNameWrap(
                    currentServices.map((service) => service.serviceName),
                    emptyText: 'لا توجد خدمات مفعلة حالياً',
                  ),
                  const Divider(height: 24),
                  _buildRequestDetailRow(
                    isActivation
                        ? 'الخدمة التي ستتم إضافتها'
                        : 'الخدمة التي ستتم إزالتها',
                    request.serviceName,
                  ),
                  _buildRequestDetailRow(
                    'نوع الطلب',
                    isActivation
                        ? 'إضافة / تفعيل خدمة'
                        : 'حذف / إلغاء تفعيل خدمة',
                  ),
                  const Divider(height: 24),
                  const Text(
                    'الخدمات بعد الموافقة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildServiceNameWrap(
                    resultingServiceNames,
                    emptyText: 'لن تبقى خدمات مفعلة',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إغلاق'),
            ),
            TextButton(
              onPressed: provider.isActionLoading
                  ? null
                  : () {
                      Navigator.of(dialogContext).pop();
                      _rejectServiceActivationRequest(request);
                    },
              child: const Text('رفض'),
            ),
            ElevatedButton(
              onPressed: provider.isActionLoading
                  ? null
                  : () {
                      Navigator.of(dialogContext).pop();
                      _approveServiceActivationRequest(request);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('قبول'),
            ),
          ],
        );
      },
    );
  }

  Future<Set<int>> _readRequestAgentServiceIds(
    AdminProvider provider,
    ActivationRequestModel request,
  ) async {
    for (final laundry in _serviceAwareLaundryAgents(provider)) {
      final agentId = AdminServiceModel.readInt(
        laundry,
        ['id', 'userID', 'userId', 'UserID'],
      );
      if (agentId == request.agentId) {
        return _agentServiceIds(laundry).toSet();
      }
    }

    try {
      final serviceIds = await provider.getAgentServiceIds(request.agentId);
      return serviceIds.toSet();
    } catch (e, s) {
      debugPrint('Failed to fetch agent service IDs for agent ${request.agentId}: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  Widget _buildRequestDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceNameWrap(
    Iterable<String> names, {
    required String emptyText,
  }) {
    final visibleNames = names.where((name) => name.trim().isNotEmpty).toList();
    if (visibleNames.isEmpty) {
      return Text(
        emptyText,
        style: const TextStyle(color: AppColors.textLight),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: visibleNames.map((name) {
        return Chip(
          label: Text(name),
          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
          labelStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }

  Future<void> _approveServiceActivationRequest(
      ActivationRequestModel request) async {
    try {
      await context.read<AdminProvider>().approveServiceActivationRequest(
            request.agentId,
            request.serviceId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم قبول طلب تعديل الخدمة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر قبول طلب تعديل الخدمة: $e')),
      );
    }
  }

  Future<void> _rejectServiceActivationRequest(
      ActivationRequestModel request) async {
    try {
      await context.read<AdminProvider>().rejectServiceActivationRequest(
            request.agentId,
            request.serviceId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفض طلب تعديل الخدمة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر رفض طلب تعديل الخدمة: $e')),
      );
    }
  }

  Future<void> _setServiceAvailability(
      AdminServiceModel service, bool isAvailable) async {
    try {
      await context
          .read<AdminProvider>()
          .setServiceAvailability(service.serviceID, isAvailable);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isAvailable ? 'تم تفعيل الخدمة' : 'تم تعطيل الخدمة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تغيير حالة الخدمة: $e')),
      );
    }
  }

  Future<void> _restoreService(AdminServiceModel service) async {
    try {
      await context.read<AdminProvider>().restoreService(service.serviceID);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم استرجاع الخدمة. التفعيل يحتاج إجراء منفصل.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر استرجاع الخدمة: $e')),
      );
    }
  }

  void _confirmDeleteService(AdminServiceModel service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الخدمة'),
        content: Text(
          service.hasHistoricalUsage || service.linkedAgentCount > 0
              ? 'هذه الخدمة مرتبطة ببيانات سابقة، سيطبق النظام الحذف الآمن إن لزم. هل تريد المتابعة؟'
              : 'هل تريد حذف هذه الخدمة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await this
                    .context
                    .read<AdminProvider>()
                    .deleteService(service.serviceID);
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الخدمة بنجاح')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('تعذر حذف الخدمة: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showServiceFormDialog({AdminServiceModel? service}) {
    final nameController =
        TextEditingController(text: service?.serviceName ?? '');
    final priceController = TextEditingController(
      text: service == null ? '' : service.price.toStringAsFixed(2),
    );
    int category = service?.category ?? 0;
    int type = service?.type ?? 0;
    int pricingModel = service?.pricingModel ?? 0;
    int deliveryModel = service?.deliveryModel ?? 0;
    bool isAvailable = service?.isAvailable ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(service == null ? 'إضافة خدمة' : 'تعديل خدمة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الخدمة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'السعر',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildServiceDropdown(
                  value: category,
                  label: 'التصنيف',
                  labels: _serviceCategoryLabels,
                  onChanged: (value) => setDialogState(() => category = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildServiceDropdown(
                  value: type,
                  label: 'النوع',
                  labels: _serviceTypeLabels,
                  onChanged: (value) => setDialogState(() => type = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildServiceDropdown(
                  value: pricingModel,
                  label: 'طريقة التسعير',
                  labels: _pricingModelLabels,
                  onChanged: (value) =>
                      setDialogState(() => pricingModel = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildServiceDropdown(
                  value: deliveryModel,
                  label: 'طريقة التنفيذ',
                  labels: _deliveryModelLabels,
                  onChanged: (value) =>
                      setDialogState(() => deliveryModel = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('الخدمة متاحة للعملاء'),
                  value: isAvailable,
                  onChanged: service?.isDeleted == true
                      ? null
                      : (value) => setDialogState(() => isAvailable = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final price = double.tryParse(priceController.text.trim());
                if (nameController.text.trim().isEmpty ||
                    price == null ||
                    price < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تأكد من اسم الخدمة والسعر')),
                  );
                  return;
                }

                final payload = {
                  'serviceName': nameController.text.trim(),
                  'category': category,
                  'type': type,
                  'price': price,
                  'pricingModel': pricingModel,
                  'deliveryModel': deliveryModel,
                  'isAvailable': isAvailable,
                };

                try {
                  if (service == null) {
                    await this
                        .context
                        .read<AdminProvider>()
                        .createService(payload);
                  } else {
                    await this
                        .context
                        .read<AdminProvider>()
                        .updateService(service.serviceID, payload);
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(service == null
                          ? 'تمت إضافة الخدمة بنجاح'
                          : 'تم تعديل الخدمة بنجاح'),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('تعذر حفظ الخدمة: $e')),
                  );
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ).then((_) {
      nameController.dispose();
      priceController.dispose();
    });
  }

  Widget _buildServiceDropdown({
    required int value,
    required String label,
    required List<String> labels,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value >= 0 && value < labels.length ? value : 0,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: List.generate(
        labels.length,
        (index) => DropdownMenuItem<int>(
          value: index,
          child: Text(labels[index]),
        ),
      ),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  List<Map<String, dynamic>> _mapApprovedStaff(List<dynamic> rawStaff) {
    return rawStaff.whereType<Map>().map((staff) {
      final role = staff['role']?.toString() ?? '';
      final isLaundry = role.toLowerCase() == 'laundryagent';
      String? documentUrl(String type) {
        final documents = staff['documents'] ?? staff['Documents'];
        if (documents is! List) return null;
        for (final document in documents.whereType<Map>()) {
          final documentType = document['type']?.toString() ??
              document['Type']?.toString() ??
              '';
          final fileUrl =
              document['fileURL'] ?? document['fileUrl'] ?? document['FileURL'];
          if (documentType.toLowerCase() == type.toLowerCase() &&
              fileUrl != null &&
              fileUrl.toString().isNotEmpty) {
            return fileUrl.toString();
          }
        }
        return null;
      }

      final firstName = staff['firstName'] ?? staff['FirstName'] ?? '';
      final lastName = staff['lastName'] ?? staff['LastName'] ?? '';
      final businessName = staff['businessName'] ?? staff['BusinessName'];
      final ratingRaw = staff['rating'] ?? staff['Rating'];

      return {
        'id': staff['userID'] ?? staff['userId'] ?? staff['UserID'],
        'name': isLaundry &&
                businessName != null &&
                businessName.toString().isNotEmpty
            ? businessName.toString()
            : '$firstName $lastName'.trim(),
        'managerName': '$firstName $lastName'.trim(),
        'type': isLaundry ? 'مغسلة' : 'سائق',
        'rating': ratingRaw is num ? ratingRaw.toDouble() : 0.0,
        'phone': staff['phoneNo'] ?? staff['PhoneNo'] ?? 'غير متوفر',
        'email': staff['email'] ?? staff['Email'] ?? '',
        'location': 'غير متوفر',
        'commercialRegister': staff['commercialRegister'] ??
            staff['CommercialRegister'] ??
            'غير متوفر',
        'nationalId': staff['nationalIDNumber'] ??
            staff['nationalIdNumber'] ??
            staff['NationalIDNumber'] ??
            'غير متوفر',
        'licenseNumber': 'غير متوفر',
        'vehicleType': staff['vehicleType']?.toString() ??
            staff['VehicleType']?.toString() ??
            'غير متوفر',
        'vehiclePlate':
            staff['plateNumber'] ?? staff['PlateNumber'] ?? 'غير متوفر',
        'commercialRegisterImage': documentUrl('CommercialRegistration'),
        'nationalIdImage': documentUrl('NationalID'),
        'storefrontImage': null,
        'licenseImage': documentUrl('DriverLicense'),
        'vehicleImage': documentUrl('VehicleImage'),
        'orders': const <String>[],
      };
    }).toList();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary),
      ),
    );
  }

  IconData _getVehicleIcon(String? vehicleType, [String? name]) {
    String? type = vehicleType;
    if (type == null && name != null) {
      final n = name.toLowerCase();
      if (n.contains('سعيد') && n.contains('عبدالله')) {
        type = 'تكتك';
      } else if (n.contains('خالد')) {
        type = 'دراجة';
      } else if (n.contains('ياسين')) {
        type = 'سيارة';
      } else if (n.contains('صالح')) {
        type = 'تكتك';
      } else if (n.contains('عمر')) {
        type = 'تكتك';
      }
    }
    if (type == null) return Icons.directions_car;
    final typeLower = type.toLowerCase();
    if (typeLower.contains('دراجة') ||
        typeLower.contains('نارية') ||
        typeLower.contains('موتور') ||
        typeLower.contains('motorcycle') ||
        typeLower.contains('bike') ||
        typeLower.contains('wheeler')) {
      return Icons.motorcycle;
    }
    if (typeLower.contains('تك') ||
        typeLower.contains('تكتك') ||
        typeLower.contains('rickshaw') ||
        typeLower.contains('tuk')) {
      return Icons.electric_rickshaw;
    }
    if (typeLower.contains('سيارة') ||
        typeLower.contains('مركبة') ||
        typeLower.contains('car') ||
        typeLower.contains('auto')) {
      return Icons.directions_car;
    }
    return Icons.directions_car; // Default fallback
  }

  Widget _buildRegistrationItem(Map<String, dynamic> request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _showRegistrationDetails(request),
        leading: CircleAvatar(
          backgroundColor: AppColors.tertiary.withValues(alpha: 0.1),
          child: Icon(
            request['type'] == 'مغسلة'
                ? Icons.local_laundry_service
                : _getVehicleIcon(request['vehicleType'], request['name']),
            color: AppColors.tertiary,
          ),
        ),
        title: Text(request['name'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('الهاتف: ${request['phone']}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle_outline,
                  color: AppColors.success),
              onPressed: () => _acceptStaff(request),
            ),
            IconButton(
              icon: const Icon(Icons.highlight_off, color: AppColors.error),
              onPressed: () => _rejectStaff(request['name']),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegistrationDetails(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: AppColors.tertiary.withValues(alpha: 0.1),
                  child: Icon(
                    request['type'] == 'مغسلة'
                        ? Icons.local_laundry_service
                        : _getVehicleIcon(
                            request['vehicleType'], request['name']),
                    size: 40,
                    color: AppColors.tertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['name'],
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        request['type'] == 'مغسلة'
                            ? 'طلب انضمام مغسلة جديدة'
                            : 'طلب انضمام مندوب توصيل',
                        style: const TextStyle(
                            color: AppColors.tertiary,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 40),
            const Text(
              'بيانات الحساب الشخصية والتسجيل',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  if (request['type'] == 'مغسلة') ...[
                    _buildDetailRow(
                        Icons.business, 'اسم المغسلة', request['name']),
                    _buildDetailRow(Icons.person, 'اسم المدير المسؤول',
                        request['managerName'] ?? 'غير متوفر'),
                    _buildDetailRow(
                        Icons.phone, 'رقم هاتف المدير', request['phone']),
                    _buildDetailRow(Icons.email, 'البريد الإلكتروني للمدير',
                        request['email'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.location_on, 'عنوان المغسلة',
                        request['location']),
                    _buildDetailRow(Icons.badge, 'رقم الهوية الوطنية للمدير',
                        request['nationalId'] ?? 'غير متوفر'),
                    _buildDetailRow(
                        Icons.assignment,
                        'رقم السجل التجاري / الترخيص',
                        request['commercialRegister'] ?? 'غير متوفر'),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'المستندات والوثائق المرفوعة',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildDocumentRow('صورة السجل التجاري / الترخيص',
                        request['commercialRegisterImage']),
                    _buildDocumentRow('صورة الهوية الوطنية للمدير',
                        request['nationalIdImage']),
                    _buildDocumentRow(
                        'صورة واجهة/لوحة المغسلة', request['storefrontImage']),
                  ] else ...[
                    _buildDetailRow(
                        Icons.person, 'اسم المندوب', request['name']),
                    _buildDetailRow(
                        Icons.phone, 'رقم هاتف المندوب', request['phone']),
                    _buildDetailRow(Icons.email, 'البريد الإلكتروني للمندوب',
                        request['email'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.location_on, 'عنوان السكن الحالي',
                        request['location']),
                    _buildDetailRow(Icons.badge, 'رقم الهوية الوطنية',
                        request['nationalId'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.card_membership, 'رقم رخصة القيادة',
                        request['licenseNumber'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.directions_car, 'نوع مركبة التوصيل',
                        request['vehicleType'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.tag, 'رقم لوحة المركبة',
                        request['vehiclePlate'] ?? 'غير متوفر'),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'المستندات والوثائق المرفوعة',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildDocumentRow(
                        'صورة رخصة القيادة للمندوب', request['licenseImage']),
                    _buildDocumentRow('صورة الهوية الوطنية للمندوب',
                        request['nationalIdImage']),
                    _buildDocumentRow('صورة المركبة الخاصة بالتوصيل',
                        request['vehicleImage']),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _acceptStaff(request);
                    },
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.white),
                    label: const Text('قبول الطلب وتفعيل الحساب',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _rejectStaff(request['name']);
                    },
                    icon: const Icon(Icons.highlight_off, color: Colors.white),
                    label: const Text('رفض الطلب',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffItem(String name, String type, double rating,
      {Map<String, dynamic>? staffData}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: staffData != null ? () => _showStaffDetails(staffData) : null,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(
              type == 'مغسلة'
                  ? Icons.local_laundry_service
                  : _getVehicleIcon(staffData?['vehicleType'], name),
              color: AppColors.primary),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            const Icon(Icons.star, size: 16, color: AppColors.warning),
            const SizedBox(width: 4),
            Text('$rating',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning),
              onPressed: () => _showWarningDialog(name),
              tooltip: 'إرسال تحذير',
            ),
            TextButton(
              onPressed: () => _dismissStaff(name, type),
              child:
                  const Text('طرد', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersView() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'إرسال عرض'),
              Tab(text: 'سجل الإشعارات'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSendOfferView(),
                _buildNotificationHistoryView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendOfferView() {
    final activeCoupons = _coupons.where((c) => !isCouponExpired(c)).toList();
    final expiredCoupons = _coupons.where((c) => isCouponExpired(c)).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'إدارة الكوبونات والعروض',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: ElevatedButton.icon(
                onPressed: _showCreateOfferDialog,
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text(
                  'إضافة عرض',
                  style: TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildOfferActionCard(
          'إرسال إشعار ترويجي عام',
          'أرسل رسالة فورية لجميع العملاء عن تنبيه أو تحديث',
          Icons.campaign,
          AppColors.secondary,
          onTap: _showNotificationDialog,
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text(
          'العروض النشطة حالياً',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (activeCoupons.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'لا توجد عروض نشطة حالياً',
                style: TextStyle(color: AppColors.textLight, fontSize: 13),
              ),
            ),
          )
        else
          ...activeCoupons.map((coupon) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: coupon['target'] == 'الجميع'
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (coupon['target'] == 'الجميع'
                                ? AppColors.primary
                                : AppColors.warning)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        coupon['target'] == 'الجميع'
                            ? Icons.confirmation_number_outlined
                            : Icons.storefront,
                        color: coupon['target'] == 'الجميع'
                            ? AppColors.primary
                            : AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(coupon['title'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('الكود: ',
                                  style: TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 12)),
                              Text(coupon['code'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                      fontSize: 13)),
                              const SizedBox(width: AppSpacing.sm),
                              Text('الخصم: ',
                                  style: TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 12)),
                              Text(coupon['discount'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                      fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person_pin_circle_outlined,
                                  size: 14, color: AppColors.textLight),
                              const SizedBox(width: 4),
                              Text('المستهدف: ${coupon['target']}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.date_range_outlined,
                                  size: 14, color: AppColors.textLight),
                              const SizedBox(width: 4),
                              Text(
                                'المدة: من ${coupon['startDate'] ?? "غير محدد"} إلى ${coupon['endDate'] ?? "غير محدد"}',
                                style: TextStyle(
                                    color: AppColors.textLight, fontSize: 12),
                              ),
                            ],
                          ),
                          if (coupon['minAmount'] != null &&
                              coupon['minAmount'].toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 14, color: AppColors.warning),
                                const SizedBox(width: 4),
                                Text(
                                  'شرط التفعيل: للطلبات أعلى من ${coupon['minAmount']} ريال',
                                  style: const TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error, size: 20),
                      onPressed: () {
                        setState(() {
                          _coupons.remove(coupon);
                        });
                        _logActivity(
                          'تم حذف الكوبون (${coupon['code']})',
                          'remove_coupon',
                          Icons.delete_outline,
                          AppColors.error,
                        );
                      },
                    ),
                  ],
                ),
              )),
        if (expiredCoupons.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'العروض المنتهية الصلاحية ⚠️',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...expiredCoupons.map((coupon) => Opacity(
                opacity: 0.6,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.block_flipped,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(coupon['title'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        decoration:
                                            TextDecoration.lineThrough)),
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'منتهي',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.error,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('الكود: ',
                                    style: TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 12)),
                                Text(coupon['code'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                        fontSize: 13)),
                                const SizedBox(width: AppSpacing.sm),
                                Text('الخصم: ',
                                    style: TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 12)),
                                Text(coupon['discount'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                        fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.date_range_outlined,
                                    size: 14, color: AppColors.textLight),
                                const SizedBox(width: 4),
                                Text(
                                  'انتهى في: ${coupon['endDate']}',
                                  style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error, size: 20),
                        onPressed: () {
                          setState(() {
                            _coupons.remove(coupon);
                          });
                          _logActivity(
                            'تم حذف الكوبون (${coupon['code']})',
                            'remove_coupon',
                            Icons.delete_outline,
                            AppColors.error,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildNotificationHistoryView() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _notificationHistory.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final note = _notificationHistory[index];
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.notifications_active,
                  color: Colors.white, size: 20),
            ),
            title: Text(note['title'],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note['body']),
                const SizedBox(height: 4),
                Text(note['date'],
                    style: TextStyle(color: AppColors.textLight, fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إرسال إشعار ترويجي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              hintText: 'عنوان الإشعار',
              controller: titleController,
            ),
            const SizedBox(height: AppSpacing.sm),
            CustomTextField(
              hintText: 'نص الإشعار...',
              maxLines: 3,
              controller: bodyController,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              titleController.dispose();
              bodyController.dispose();
              Navigator.pop(context);
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text;
              titleController.dispose();
              bodyController.dispose();
              Navigator.pop(context);
              _logActivity(
                'تم إرسال إشعار ترويجي جماعي: "$title"',
                'send_notification',
                Icons.notifications_active,
                AppColors.primary,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'تم إرسال الإشعار${title.isNotEmpty ? ": $title" : ""}')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child:
                const Text('إرسال الآن', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateOfferDialog() {
    final titleController = TextEditingController();
    final codeController = TextEditingController();
    final discountController = TextEditingController();
    final minAmountController = TextEditingController();
    String selectedTarget = 'الجميع';
    String selectedOfferType = 'Percentage'; // 'Percentage' or 'FixedAmount'
    DateTime? startDate;
    DateTime? endDate;
    bool hasCondition = false;

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final approvedStaff = _mapApprovedStaff(adminProvider.approvedStaff);
    final laundryNames = approvedStaff
        .where((s) => s['type'] == 'مغسلة')
        .map((s) => s['name'].toString())
        .toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'إضافة عرض أو كوبون جديد',
            style: TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  hintText: 'اسم العرض (مثال: خصم الصيف)',
                  controller: titleController,
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  hintText: 'كود الخصم (مثال: SUMMER25)',
                  controller: codeController,
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  hintText: 'قيمة الخصم (مثال: 20% أو 500 ريال)',
                  controller: discountController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'نوع الخصم:',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedOfferType,
                      isExpanded: true,
                      dropdownColor: theme.cardColor,
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'Percentage',
                          child: Text('نسبة مئوية (%)'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'FixedAmount',
                          child: Text('مبلغ ثابت (ريال)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedOfferType = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'الفئة المستهدفة:',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedTarget,
                      isExpanded: true,
                      dropdownColor: theme.cardColor,
                      items: [
                        'الجميع',
                        ...laundryNames,
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedTarget = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'مدة العرض:',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setDialogState(() => startDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  startDate == null
                                      ? 'تاريخ البدء'
                                      : '${startDate!.year}/${startDate!.month.toString().padLeft(2, '0')}/${startDate!.day.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: startDate == null
                                        ? Colors.grey.shade600
                                        : theme.colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate ??
                                DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setDialogState(() => endDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  endDate == null
                                      ? 'تاريخ الانتهاء'
                                      : '${endDate!.year}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.day.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: endDate == null
                                        ? Colors.grey.shade600
                                        : theme.colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  title: Text(
                    'تفعيل شرط على العرض',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface),
                  ),
                  subtitle: const Text(
                    'مثال: للطلبات التي تتجاوز مبلغاً معيناً',
                    style: TextStyle(fontSize: 10, color: AppColors.textLight),
                  ),
                  value: hasCondition,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setDialogState(() => hasCondition = val);
                  },
                ),
                if (hasCondition) ...[
                  const SizedBox(height: AppSpacing.xs),
                  CustomTextField(
                    hintText: 'الحد الأدنى لقيمة الطلب بالريال (مثال: 5000)',
                    controller: minAmountController,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                titleController.dispose();
                codeController.dispose();
                discountController.dispose();
                minAmountController.dispose();
                Navigator.pop(context);
              },
              child: const Text('إلغاء',
                  style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty ||
                    codeController.text.isEmpty) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('الرجاء تعبئة اسم العرض وكود الخصم')),
                  );
                  return;
                }

                // Validate discount field
                if (discountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يجب إدخال قيمة الخصم')),
                  );
                  return;
                }

                // Validate discount is a valid number
                final discountValue =
                    double.tryParse(discountController.text.trim());
                if (discountValue == null) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('قيمة الخصم يجب أن تكون رقماً صالحاً')),
                  );
                  return;
                }

                // If percentage, validate it is between 1 and 100
                if (selectedOfferType == 'Percentage' &&
                    (discountValue <= 0 || discountValue > 100)) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'النسبة المئوية للخصم يجب أن تكون بين 1 و 100')),
                  );
                  return;
                }

                // If fixed amount, validate it is greater than 0
                if (selectedOfferType == 'FixedAmount' && discountValue <= 0) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('يجب أن تكون قيمة الخصم أكبر من صفر')),
                  );
                  return;
                }

                // Enforce date checks
                if (startDate == null || endDate == null) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('يجب تحديد تاريخ البدء وتاريخ الانتهاء')),
                  );
                  return;
                }

                if (!endDate!.isAfter(startDate!)) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('تاريخ الانتهاء يجب أن يكون بعد تاريخ البدء')),
                  );
                  return;
                }

                // Check for duplicate codes
                final upperCode = codeController.text.toUpperCase();
                final isDuplicate = _coupons.any((c) => c['code'] == upperCode);
                if (isDuplicate) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('كود الكوبون موجود بالفعل')),
                  );
                  return;
                }

                // Store raw numeric discount value, format only for display
                String storedDiscount;
                String displayDiscount;
                if (selectedOfferType == 'Percentage') {
                  storedDiscount = '${discountValue.toStringAsFixed(0)}%';
                  displayDiscount = storedDiscount;
                } else {
                  // Store raw numeric value for FixedAmount
                  storedDiscount = discountValue.toStringAsFixed(0);
                  displayDiscount = '$storedDiscount ريال';
                }

                setState(() {
                  _coupons.add({
                    'title': titleController.text,
                    'code': upperCode,
                    'discount': storedDiscount,
                    'displayDiscount': displayDiscount,
                    'target': selectedTarget,
                    'status': 'نشط',
                    'startDate':
                        '${startDate!.year}/${startDate!.month.toString().padLeft(2, '0')}/${startDate!.day.toString().padLeft(2, '0')}',
                    'endDate':
                        '${endDate!.year}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.day.toString().padLeft(2, '0')}',
                    'minAmount': hasCondition ? minAmountController.text : null,
                    'type': selectedOfferType,
                  });
                });
                _logActivity(
                  'تم إضافة عرض/كوبون جديد ($upperCode) بخصم $displayDiscount',
                  'add_coupon',
                  Icons.local_offer,
                  AppColors.primary,
                );
                titleController.dispose();
                codeController.dispose();
                discountController.dispose();
                minAmountController.dispose();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إضافة العرض بنجاح')),
                );
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('إضافة العرض',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildOfferActionCard(
      String title, String subtitle, IconData icon, Color color,
      {required VoidCallback onTap}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedIndex >= 5) {
      _selectedIndex = 0;
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _selectedIndex == 4
          ? null
          : AppBar(
              elevation: 0,
              backgroundColor: AppColors.white,
              automaticallyImplyLeading: false,
              centerTitle: true,
              title: Text(
                _currentTitle,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeView(),
          _buildRegistrationsView(),
          _buildLaundryFirstServicesView(),
          _buildOffersView(),
          AdminProfileScreen(
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index >= 2 ? index + 1 : index;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textLight,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'التسجيلات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.cleaning_services_outlined),
              activeIcon: Icon(Icons.cleaning_services),
              label: 'الخدمات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_offer_outlined),
              activeIcon: Icon(Icons.local_offer),
              label: 'العروض',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}

bool isCouponExpired(Map<String, dynamic> coupon) {
  final endDateStr = coupon['endDate'];
  if (endDateStr == null || endDateStr == 'غير محدد') {
    return false;
  }
  try {
    final parts = endDateStr.split('/');
    if (parts.length == 3) {
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final endDate = DateTime(year, month, day, 23, 59, 59);
      return DateTime.now().isAfter(endDate);
    }
  } catch (_) {
    // If parsing fails, fall back to active
  }
  return false;
}
