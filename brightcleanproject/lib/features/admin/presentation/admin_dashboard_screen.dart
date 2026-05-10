import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _systemSuspended = false;

  // State variables for dynamic counts
  final int _customersCount = 850;
  final double _totalRevenue = 450000.0; // Adjusted for Yemeni Rial
  final int _totalOrders = 1250;

  String _searchQuery = '';

  // Dummy data for live orders
  final List<Map<String, dynamic>> _liveOrders = [
    {
      'id': '1080',
      'status': 'استلام',
      'type': 'غسيل وكي',
      'driver': 'ياسين أحمد',
      'time': '10 دقائق'
    },
    {
      'id': '1081',
      'status': 'غسيل',
      'type': 'تنظيف جاف',
      'laundry': 'مغسلة الفاخرة',
      'time': '30 دقيقة'
    },
    {
      'id': '1082',
      'status': 'توصيل',
      'type': 'كي فقط',
      'driver': 'خالد سعيد',
      'time': '5 دقائق'
    },
  ];

  List<FlSpot> _getRevenueSpots() {
    return const [
      FlSpot(0, 30),
      FlSpot(1, 45),
      FlSpot(2, 35),
      FlSpot(3, 50),
      FlSpot(4, 48),
      FlSpot(5, 60),
      FlSpot(6, 55),
    ];
  }

  // Dummy data for pending requests
  final List<Map<String, dynamic>> _pendingRequests = [
    {
      'name': 'مغسلة النور',
      'type': 'مغسلة',
      'phone': '777123456',
      'location': 'صنعاء، التحرير'
    },
    {
      'name': 'مغسلة الصفاء',
      'type': 'مغسلة',
      'phone': '771122334',
      'location': 'تعز، شارع جمال'
    },
    {
      'name': 'سعيد عبدالله',
      'type': 'سائق',
      'phone': '733445566',
      'location': 'عدن، كريتر'
    },
    {
      'name': 'محمد علي',
      'type': 'سائق',
      'phone': '711223344',
      'location': 'حضرموت، المكلا'
    },
  ];

  // Dummy data for staff members
  final List<Map<String, dynamic>> _staffMembers = [
    {
      'name': 'مغسلة الفاخرة',
      'type': 'مغسلة',
      'rating': 4.8,
      'phone': '777111222',
      'location': 'صنعاء، حدة',
      'orders': ['طلب #1024 - مكتمل', 'طلب #1055 - قيد التنفيذ'],
    },
    {
      'name': 'مغسلة البركة',
      'type': 'مغسلة',
      'rating': 4.5,
      'phone': '770111222',
      'location': 'صنعاء، السبعين',
      'orders': ['طلب #1030 - مكتمل'],
    },
    {
      'name': 'خالد سعيد',
      'type': 'سائق',
      'rating': 4.9,
      'phone': '733111222',
      'location': 'عدن، المنصورة',
      'orders': ['طلب #1060 - في الطريق', 'طلب #1061 - قيد التوصيل'],
    },
    {
      'name': 'ياسين أحمد',
      'type': 'سائق',
      'rating': 4.2,
      'phone': '711111222',
      'location': 'إب، الظهار',
      'orders': ['طلب #1070 - مكتمل'],
    },
  ];

  final List<Map<String, dynamic>> _notificationHistory = [
    {
      'title': 'خصم 20% بمناسبة العيد',
      'body': 'استخدم الكود EID20 للحصول على الخصم الآن!',
      'date': '2024-05-01'
    },
    {
      'title': 'مغاسل جديدة في منطقتك',
      'body': 'تم انضمام 5 مغاسل جديدة في منطقة حدة.',
      'date': '2024-04-28'
    },
  ];

  final List<String> _titles = [
    'الرئيسية',
    'إدارة التسجيلات',
    'العروض',
    'الإعدادات'
  ];

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              try {
                // Clear authentication state from SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('authToken');
                await prefs.remove('refreshToken');
                await prefs.remove('user_id');
                await prefs.remove('user_name');
                await prefs.remove('user_phone');
                await prefs.remove('user_role');
                await prefs.remove('wallet_balance');

                // Close dialog and navigate to login
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go('/login');
                }
              } catch (e) {
                // Handle errors in clearing auth state
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ أثناء تسجيل الخروج: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('خروج', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
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

  void _acceptStaff(Map<String, dynamic> request) {
    setState(() {
      // Move from pending to approved
      _pendingRequests.removeWhere((r) => r['name'] == request['name']);
      _staffMembers.add({
        'name': request['name'],
        'type': request['type'],
        'rating': 5.0, // Initial rating
        'phone': request['phone'],
        'location': request['location'],
        'orders': [],
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم قبول ${request['name']} بنجاح')),
    );
  }

  void _rejectStaff(String name) {
    setState(() {
      _pendingRequests.removeWhere((r) => r['name'] == name);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم رفض طلب $name')),
    );
  }

  void _dismissStaff(String name, String type) {
    setState(() {
      _staffMembers.removeWhere((m) => m['name'] == name);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم طرد $name ($type) من النظام')),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('نمو الإيرادات (أسبوعي)',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getRevenueSpots(),
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
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _liveOrders.length,
            itemBuilder: (context, index) {
              final order = _liveOrders[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(left: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                ),
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
      curve:
          Interval(start, end, curve: Curves.easeOut),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
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

  Widget _buildHomeView() {
    final driversCount = _staffMembers.where((s) => s['type'] == 'سائق').length;
    final laundriesCount =
        _staffMembers.where((s) => s['type'] == 'مغسلة').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 20),
          _buildRevenueChart(),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildStatCard('إجمالي الطلبات', '$_totalOrders',
                  Icons.shopping_bag_outlined, AppColors.primary,
                  delay: 0),
              _buildStatCard(
                  'الإيرادات',
                  '${_totalRevenue.toStringAsFixed(0)} ر.ي',
                  Icons.account_balance_wallet_outlined,
                  AppColors.success,
                  delay: 100),
              _buildStatCard('عدد العملاء', '$_customersCount',
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
          const SizedBox(height: 24),
          _buildLiveOrdersSection(),
          const SizedBox(height: 24),
          const Text(
            'الطلبات الأخيرة',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          // Placeholder for recent orders list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.receipt_long,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('طلب #102${index + 4}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text('عميل: أحمد محمد',
                            style: TextStyle(
                                color: AppColors.textLight, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Text('12,500 ر.ي',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success)),
                ],
              ),
            ),
          ),
        ],
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
    final laundries =
        _pendingRequests.where((r) => r['type'] == 'مغسلة').toList();
    final drivers = _pendingRequests.where((r) => r['type'] == 'سائق').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('المغاسل'),
        if (laundries.isEmpty)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('لا توجد طلبات مغاسل حالياً'))),
        ...laundries.map((r) => _buildRegistrationItem(r)),
        const SizedBox(height: 20),
        _buildSectionHeader('السائقين'),
        if (drivers.isEmpty)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('لا توجد طلبات مناديب حالياً'))),
        ...drivers.map((r) => _buildRegistrationItem(r)),
      ],
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
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(
                    staff['type'] == 'مغسلة'
                        ? Icons.local_laundry_service
                        : Icons.drive_eta,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 20),
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
            const Text('المعلومات الشخصية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.phone, 'رقم الهاتف', staff['phone']),
            _buildDetailRow(Icons.location_on, 'الموقع', staff['location']),
            const SizedBox(height: 24),
            const Text('الطلبات الحالية/السابقة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: staff['orders'].length,
                itemBuilder: (context, index) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.receipt_long, color: AppColors.tertiary),
                  title: Text(staff['orders'][index]),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                const SizedBox(width: 12),
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
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: AppColors.textLight)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildApprovedStaff() {
    final filteredStaff = _staffMembers.where((staff) {
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
              const SizedBox(height: 20),
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

  Widget _buildRegistrationItem(Map<String, dynamic> request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.tertiary.withValues(alpha: 0.1),
          child: Icon(
            request['type'] == 'مغسلة'
                ? Icons.local_laundry_service
                : Icons.drive_eta,
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
              type == 'مغسلة' ? Icons.local_laundry_service : Icons.drive_eta,
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'إدارة العروض والتسويق',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        _buildOfferActionCard(
          'إرسال إشعار ترويجي',
          'أرسل رسالة فورية لجميع العملاء عن عرض جديد',
          Icons.campaign,
          AppColors.secondary,
          onTap: _showNotificationDialog,
        ),
        const SizedBox(height: 16),
        _buildOfferActionCard(
          'إضافة عرض جديد',
          'قم بإنشاء كود خصم أو عرض خاص لفترة محدودة',
          Icons.add_circle_outline,
          AppColors.success,
          onTap: () {},
        ),
        const SizedBox(height: 24),
        const Text(
          'العروض النشطة حالياً',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildActiveOfferCard('خصم العيد', '15%', 'تنتهي بعد يومين'),
        _buildActiveOfferCard('أول غسلة مجاناً', '100%', 'مستمر'),
      ],
    );
  }

  Widget _buildNotificationHistoryView() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _notificationHistory.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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

  Widget _buildOfferActionCard(
      String title, String subtitle, IconData icon, Color color,
      {required VoidCallback onTap}) {
    return Container(
      padding: const EdgeInsets.all(16),
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

  Widget _buildActiveOfferCard(String title, String discount, String expiry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(expiry, style: TextStyle(color: AppColors.textLight)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            discount,
            style: const TextStyle(
                color: AppColors.success, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'الإعدادات العامة',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        _buildSettingTile(
          'وضع الصيانة',
          'إيقاف استقبال الطلبات الجديدة مؤقتاً',
          Icons.settings_suggest,
          trailing: Switch(
            value: _systemSuspended,
            onChanged: (v) => setState(() => _systemSuspended = v),
            activeThumbColor: AppColors.error,
          ),
        ),
        if (_systemSuspended)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              children: [
                const CustomTextField(
                    hintText: 'رسالة الصيانة التي ستظهر للمستخدمين...'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary),
                  child: const Text('حفظ الرسالة',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        _buildSettingTile(
          'إشعارات النظام',
          'تلقي تنبيهات عند حدوث مشاكل تقنية',
          Icons.notifications_active_outlined,
          trailing: const Icon(Icons.chevron_right),
        ),
        const Divider(height: 32),
        const Text(
          'التقارير والتصدير',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        _buildExportTile('تقرير الإيرادات (PDF)',
            'تحميل ملخص مالي للأسبوع الحالي', Icons.picture_as_pdf, Colors.red),
        _buildExportTile(
            'أداء الموظفين (Excel)',
            'تقرير مفصل عن تقييمات المغاسل والمناديب',
            Icons.table_chart,
            Colors.green),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleLogout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildExportTile(
      String title, String subtitle, IconData icon, Color color) {
    return _buildSettingTile(
      title,
      subtitle,
      icon,
      trailing: IconButton(
        icon: const Icon(Icons.file_download, color: AppColors.primary),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('جاري تصدير $title...')),
          );
        },
      ),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon,
      {required Widget trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: trailing,
        onTap: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: _selectedIndex == 0
            ? PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleLogout();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 20),
                        SizedBox(width: 10),
                        Text('الملف الشخصي'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 20),
                        SizedBox(width: 10),
                        Text('الإعدادات'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: AppColors.error, size: 20),
                        SizedBox(width: 10),
                        Text('تسجيل الخروج',
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.admin_panel_settings,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'أهلاً بك،',
                          style: TextStyle(
                              color: AppColors.textLight, fontSize: 12),
                        ),
                        Text(
                          'المشرف الرئيسي',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : Center(
                child: Text(
                  _titles[_selectedIndex],
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeView(),
          _buildRegistrationsView(),
          _buildOffersView(),
          _buildSettingsView(),
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
              icon: Icon(Icons.local_offer_outlined),
              activeIcon: Icon(Icons.local_offer),
              label: 'العروض',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}
