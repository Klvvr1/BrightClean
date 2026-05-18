import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/widgets/custom_text_field.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  static final List<Map<String, dynamic>> couponsList = [
    {
      'title': 'خصم العيد',
      'code': 'EID2026',
      'discount': '15%',
      'target': 'الجميع',
      'status': 'نشط',
      'startDate': '2026/05/01',
      'endDate': '2026/06/30',
      'minAmount': '150',
    },
    {
      'title': 'أول غسلة مجاناً',
      'code': 'FIRSTFREE',
      'discount': '100%',
      'target': 'الجميع',
      'status': 'نشط',
      'startDate': '2026/01/01',
      'endDate': '2026/12/31',
      'minAmount': null,
    },
  ];

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _systemSuspended = false;
  bool _systemNotificationsEnabled = true;

  // State variables for dynamic counts
  final int _customersCount = 850;
  final double _totalRevenue = 450000.0; // Adjusted for Yemeni Rial
  final int _totalOrders = 1250;

  String _searchQuery = '';
  List<Map<String, dynamic>> get _coupons => AdminDashboardScreen.couponsList;


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
      'managerName': 'عبدالرحمن صالح',
      'type': 'مغسلة',
      'phone': '777123456',
      'email': 'alnoor.laundry@gmail.com',
      'location': 'صنعاء، التحرير',
      'commercialRegister': 'CR-2026-99211',
      'nationalId': '1092837465',
      'commercialRegisterImage': 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?q=80&w=600',
      'nationalIdImage': 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?q=80&w=600',
      'storefrontImage': 'https://images.unsplash.com/photo-1545173168-9f1947e8017e?q=80&w=600',
    },
    {
      'name': 'مغسلة الصفاء',
      'managerName': 'ماجد القاضي',
      'type': 'مغسلة',
      'phone': '771122334',
      'email': 'alsafaa.laundry@gmail.com',
      'location': 'تعز، شارع جمال',
      'commercialRegister': 'CR-2026-88401',
      'nationalId': '1088492019',
      'commercialRegisterImage': 'https://images.unsplash.com/photo-1450133064473-71024230f91b?q=80&w=600',
      'nationalIdImage': 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?q=80&w=600',
      'storefrontImage': 'https://images.unsplash.com/photo-1528238646472-f23945aca686?q=80&w=600',
    },
    {
      'name': 'سعيد عبدالله',
      'type': 'سائق',
      'phone': '733445566',
      'email': 'saeed.abdullah@gmail.com',
      'location': 'عدن، كريتر',
      'nationalId': '2083746519',
      'licenseNumber': 'DL-9827364',
      'vehicleType': 'تك تك (أصفر)',
      'vehiclePlate': 'عدن - 12345',
      'licenseImage': 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?q=80&w=600',
      'nationalIdImage': 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?q=80&w=600',
      'vehicleImage': 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?q=80&w=600',
    },
    {
      'name': 'محمد علي',
      'type': 'سائق',
      'phone': '711223344',
      'email': 'mohamed.ali@gmail.com',
      'location': 'حضرموت، المكلا',
      'nationalId': '2055483921',
      'licenseNumber': 'DL-8840291',
      'vehicleType': 'سيارة صغيرة (تويوتا)',
      'vehiclePlate': 'حضرموت - 9982',
      'licenseImage': 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?q=80&w=600',
      'nationalIdImage': 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?q=80&w=600',
      'vehicleImage': 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?q=80&w=600',
    },
    {
      'name': 'عمر سليم',
      'type': 'سائق',
      'phone': '775566778',
      'email': 'omar.saleem@gmail.com',
      'location': 'تعز، الحوبان',
      'nationalId': '2094830192',
      'licenseNumber': 'DL-5548392',
      'vehicleType': 'تك تك (أحمر)',
      'vehiclePlate': 'تعز - 4820',
      'licenseImage': 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?q=80&w=600',
      'nationalIdImage': 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?q=80&w=600',
      'vehicleImage': 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?q=80&w=600',
    },
  ];

  // Dummy data for staff members
  final List<Map<String, dynamic>> _staffMembers = [
    {
      'name': 'مغسلة الفاخرة',
      'managerName': 'حسين العنسي',
      'type': 'مغسلة',
      'rating': 4.8,
      'phone': '777111222',
      'email': 'alfakhera@laundry.com',
      'location': 'صنعاء، حدة',
      'commercialRegister': 'CR-2025-1029',
      'nationalId': '1049283719',
      'commercialRegisterImage': 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?q=80&w=600',
      'nationalIdImage': 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?q=80&w=600',
      'storefrontImage': 'https://images.unsplash.com/photo-1545173168-9f1947e8017e?q=80&w=600',
      'orders': ['طلب #1024 - مكتمل', 'طلب #1055 - قيد التنفيذ'],
    },
    {
      'name': 'مغسلة البركة',
      'managerName': 'فؤاد المخلافي',
      'type': 'مغسلة',
      'rating': 4.5,
      'phone': '770111222',
      'email': 'albaraka@laundry.com',
      'location': 'صنعاء، السبعين',
      'commercialRegister': 'CR-2025-4820',
      'nationalId': '1058291039',
      'commercialRegisterImage': 'https://images.unsplash.com/photo-1450133064473-71024230f91b?q=80&w=600',
      'nationalIdImage': 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?q=80&w=600',
      'storefrontImage': 'https://images.unsplash.com/photo-1528238646472-f23945aca686?q=80&w=600',
      'orders': ['طلب #1030 - مكتمل'],
    },
    {
      'name': 'خالد سعيد',
      'type': 'سائق',
      'rating': 4.9,
      'phone': '733111222',
      'email': 'khaled.saeed@driver.com',
      'location': 'عدن، المنصورة',
      'nationalId': '2039281039',
      'licenseNumber': 'DL-1928302',
      'vehicleType': 'دراجة نارية (ياماها)',
      'vehiclePlate': 'عدن - 9821',
      'licenseImage': 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?q=80&w=600',
      'nationalIdImage': 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?q=80&w=600',
      'vehicleImage': 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?q=80&w=600',
      'orders': ['طلب #1060 - في الطريق', 'طلب #1061 - قيد التوصيل'],
    },
    {
      'name': 'ياسين أحمد',
      'type': 'سائق',
      'rating': 4.2,
      'phone': '711111222',
      'email': 'yassin.ahmed@driver.com',
      'location': 'إب، الظهار',
      'nationalId': '2019284029',
      'licenseNumber': 'DL-2938401',
      'vehicleType': 'سيارة (هوندا)',
      'vehiclePlate': 'إب - 3381',
      'licenseImage': 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?q=80&w=600',
      'nationalIdImage': 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?q=80&w=600',
      'vehicleImage': 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?q=80&w=600',
      'orders': ['طلب #1070 - مكتمل'],
    },
    {
      'name': 'صالح مرشد',
      'type': 'سائق',
      'rating': 4.7,
      'phone': '772233445',
      'email': 'saleh.morshed@driver.com',
      'location': 'صنعاء، باب اليمن',
      'nationalId': '2093840192',
      'licenseNumber': 'DL-8849201',
      'vehicleType': 'تكتك (أزرق)',
      'vehiclePlate': 'صنعاء - 9021',
      'licenseImage': 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?q=80&w=600',
      'nationalIdImage': 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?q=80&w=600',
      'vehicleImage': 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?q=80&w=600',
      'orders': ['طلب #1080 - مكتمل'],
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

  final List<Map<String, dynamic>> _adminActivities = [
    {
      'title': 'تم قبول طلب انضمام "مغسلة الفاخرة" وتفعيل الحساب',
      'type': 'add_laundry',
      'time': 'منذ 10 دقائق',
      'icon': Icons.business,
      'color': AppColors.success,
    },
    {
      'title': 'تم إضافة كوبون خصم جديد (EID20)',
      'type': 'add_coupon',
      'time': 'منذ ساعة',
      'icon': Icons.local_offer,
      'color': AppColors.primary,
    },
    {
      'title': 'تم إرسال تحذير رسمي للمندوب "ياسين أحمد"',
      'type': 'warning',
      'time': 'منذ ساعتين',
      'icon': Icons.warning_amber_rounded,
      'color': AppColors.warning,
    },
    {
      'title': 'تم قبول طلب انضمام المندوب "خالد سعيد"',
      'type': 'add_driver',
      'time': 'اليوم 09:30 ص',
      'icon': Icons.person_add,
      'color': AppColors.success,
    },
    {
      'title': 'تم حذف كوبون الخصم المنتهي (SUMMER24)',
      'type': 'remove_coupon',
      'time': 'أمس 04:15 م',
      'icon': Icons.delete_outline,
      'color': AppColors.error,
    },
  ];

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
    'العروض'
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

  void _acceptStaff(Map<String, dynamic> request) {
    setState(() {
      // Move from pending to approved
      _pendingRequests.removeWhere((r) => r['name'] == request['name']);
      _staffMembers.add({
        'name': request['name'],
        'managerName': request['managerName'],
        'type': request['type'],
        'rating': 5.0, // Initial rating
        'phone': request['phone'],
        'email': request['email'],
        'location': request['location'],
        'commercialRegister': request['commercialRegister'],
        'nationalId': request['nationalId'],
        'licenseNumber': request['licenseNumber'],
        'vehicleType': request['vehicleType'],
        'vehiclePlate': request['vehiclePlate'],
        'orders': [],
      });
    });
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
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            const SizedBox(width: 10),
            const Text(
              'تأكيد طرد من النظام',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
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
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textLight)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('نعم، طرد من النظام', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppStyles.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('نمو الإيرادات (أسبوعي)',
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

  Widget _buildHomeView() {
    final driversCount = _staffMembers.where((s) => s['type'] == 'سائق').length;
    final laundriesCount =
        _staffMembers.where((s) => s['type'] == 'مغسلة').length;

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
          _buildRevenueChart(),
          const SizedBox(height: AppSpacing.xl),
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
          // Placeholder for recent orders list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: AppStyles.surface(context),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.receipt_long,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
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
                child: const Text('عرض الكل', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
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
                    color: (_systemSuspended ? AppColors.error : AppColors.primary).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.settings_suggest,
                    color: _systemSuspended ? AppColors.error : AppColors.primary,
                  ),
                ),
                title: const Text('وضع الصيانة للنظام',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('إيقاف استقبال طلبات الغسيل الجديدة مؤقتاً',
                    style: TextStyle(fontSize: 12)),
                trailing: Switch(
                  value: _systemSuspended,
                  onChanged: (v) {
                    setState(() {
                      _systemSuspended = v;
                    });
                    _logActivity(
                      v ? 'تم تفعيل وضع صيانة النظام' : 'تم إلغاء وضع صيانة النظام',
                      v ? 'error' : 'success',
                      Icons.settings_suggest,
                      v ? AppColors.error : AppColors.success,
                    );
                  },
                  activeThumbColor: AppColors.error,
                ),
              ),
              if (_systemSuspended) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
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
                      const CustomTextField(
                          hintText: 'رسالة الصيانة التي ستظهر للعملاء...'),
                      const SizedBox(height: AppSpacing.xs),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم حفظ رسالة الصيانة بنجاح!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('حفظ ونشر الرسالة للعملاء',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                subtitle: const Text('تنبيهات فورية للمشرف عن المشاكل التقنية والشكاوى',
                    style: TextStyle(fontSize: 12)),
                trailing: Switch(
                  value: _systemNotificationsEnabled,
                  onChanged: (v) {
                    setState(() {
                      _systemNotificationsEnabled = v;
                    });
                    _logActivity(
                      v ? 'تم تفعيل إشعارات النظام الذكية' : 'تم تعطيل إشعارات النظام الذكية',
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
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
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
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
    final laundries =
        _pendingRequests.where((r) => r['type'] == 'مغسلة').toList();
    final drivers = _pendingRequests.where((r) => r['type'] == 'سائق').toList();

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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  if (staff['type'] == 'مغسلة') ...[
                    _buildDetailRow(Icons.business, 'اسم المغسلة', staff['name']),
                    _buildDetailRow(Icons.person, 'اسم المدير المسؤول', staff['managerName'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.phone, 'رقم الهاتف', staff['phone']),
                    _buildDetailRow(Icons.email, 'البريد الإلكتروني', staff['email'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.location_on, 'الموقع', staff['location']),
                    _buildDetailRow(Icons.badge, 'رقم الهوية الوطنية للمدير', staff['nationalId'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.assignment, 'رقم السجل التجاري / الترخيص', staff['commercialRegister'] ?? 'غير متوفر'),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'المستندات والوثائق المرفوعة',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildDocumentRow('صورة السجل التجاري / الترخيص', staff['commercialRegisterImage']),
                    _buildDocumentRow('صورة الهوية الوطنية للمدير', staff['nationalIdImage']),
                    _buildDocumentRow('صورة واجهة/لوحة المغسلة', staff['storefrontImage']),
                  ] else ...[
                    _buildDetailRow(Icons.person, 'اسم المندوب', staff['name']),
                    _buildDetailRow(Icons.phone, 'رقم الهاتف', staff['phone']),
                    _buildDetailRow(Icons.email, 'البريد الإلكتروني', staff['email'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.location_on, 'الموقع', staff['location']),
                    _buildDetailRow(Icons.badge, 'رقم الهوية الوطنية', staff['nationalId'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.card_membership, 'رقم رخصة القيادة', staff['licenseNumber'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.directions_car, 'نوع مركبة التوصيل', staff['vehicleType'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.tag, 'رقم لوحة المركبة', staff['vehiclePlate'] ?? 'غير متوفر'),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'المستندات والوثائق المرفوعة',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildDocumentRow('صورة رخصة القيادة للمندوب', staff['licenseImage']),
                    _buildDocumentRow('صورة الهوية الوطنية للمندوب', staff['nationalIdImage']),
                    _buildDocumentRow('صورة المركبة الخاصة بالتوصيل', staff['vehicleImage']),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  const Text('الطلبات الحالية/السابقة',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: AppSpacing.sm),
                  if (staff['orders'] == null || staff['orders'].isEmpty)
                    const Text('لا توجد طلبات مسجلة حالياً', style: TextStyle(color: AppColors.textLight))
                  else
                    ...staff['orders'].map<Widget>((order) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.receipt_long, color: AppColors.tertiary),
                          title: Text(order),
                        )).toList(),
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
            imageUrl,
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
        onTap: () => _showImagePreviewDialog(label, imageUrl),
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
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
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
                        : _getVehicleIcon(request['vehicleType'], request['name']),
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
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        request['type'] == 'مغسلة' ? 'طلب انضمام مغسلة جديدة' : 'طلب انضمام مندوب توصيل',
                        style: const TextStyle(color: AppColors.tertiary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 40),
            const Text(
              'بيانات الحساب الشخصية والتسجيل',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  if (request['type'] == 'مغسلة') ...[
                    _buildDetailRow(Icons.business, 'اسم المغسلة', request['name']),
                    _buildDetailRow(Icons.person, 'اسم المدير المسؤول', request['managerName'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.phone, 'رقم هاتف المدير', request['phone']),
                    _buildDetailRow(Icons.email, 'البريد الإلكتروني للمدير', request['email'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.location_on, 'عنوان المغسلة', request['location']),
                    _buildDetailRow(Icons.badge, 'رقم الهوية الوطنية للمدير', request['nationalId'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.assignment, 'رقم السجل التجاري / الترخيص', request['commercialRegister'] ?? 'غير متوفر'),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'المستندات والوثائق المرفوعة',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildDocumentRow('صورة السجل التجاري / الترخيص', request['commercialRegisterImage']),
                    _buildDocumentRow('صورة الهوية الوطنية للمدير', request['nationalIdImage']),
                    _buildDocumentRow('صورة واجهة/لوحة المغسلة', request['storefrontImage']),
                  ] else ...[
                    _buildDetailRow(Icons.person, 'اسم المندوب', request['name']),
                    _buildDetailRow(Icons.phone, 'رقم هاتف المندوب', request['phone']),
                    _buildDetailRow(Icons.email, 'البريد الإلكتروني للمندوب', request['email'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.location_on, 'عنوان السكن الحالي', request['location']),
                    _buildDetailRow(Icons.badge, 'رقم الهوية الوطنية', request['nationalId'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.card_membership, 'رقم رخصة القيادة', request['licenseNumber'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.directions_car, 'نوع مركبة التوصيل', request['vehicleType'] ?? 'غير متوفر'),
                    _buildDetailRow(Icons.tag, 'رقم لوحة المركبة', request['vehiclePlate'] ?? 'غير متوفر'),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'المستندات والوثائق المرفوعة',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildDocumentRow('صورة رخصة القيادة للمندوب', request['licenseImage']),
                    _buildDocumentRow('صورة الهوية الوطنية للمندوب', request['nationalIdImage']),
                    _buildDocumentRow('صورة المركبة الخاصة بالتوصيل', request['vehicleImage']),
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
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: const Text('قبول الطلب وتفعيل الحساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    label: const Text('رفض الطلب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
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
                        color: (coupon['target'] == 'الجميع' ? AppColors.primary : AppColors.warning)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        coupon['target'] == 'الجميع' ? Icons.confirmation_number_outlined : Icons.storefront,
                        color: coupon['target'] == 'الجميع' ? AppColors.primary : AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(coupon['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('الكود: ', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                              Text(coupon['code'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 13)),
                              const SizedBox(width: AppSpacing.sm),
                              Text('الخصم: ', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                              Text(coupon['discount'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person_pin_circle_outlined, size: 14, color: AppColors.textLight),
                              const SizedBox(width: 4),
                              Text('المستهدف: ${coupon['target']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.date_range_outlined, size: 14, color: AppColors.textLight),
                              const SizedBox(width: 4),
                              Text(
                                'المدة: من ${coupon['startDate'] ?? "غير محدد"} إلى ${coupon['endDate'] ?? "غير محدد"}',
                                style: TextStyle(color: AppColors.textLight, fontSize: 12),
                              ),
                            ],
                          ),
                          if (coupon['minAmount'] != null && coupon['minAmount'].toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                                const SizedBox(width: 4),
                                Text(
                                  'شرط التفعيل: للطلبات أعلى من ${coupon['minAmount']} ريال',
                                  style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.error),
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
                                Text(coupon['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, decoration: TextDecoration.lineThrough)),
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'منتهي',
                                    style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('الكود: ', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                                Text(coupon['code'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 13)),
                                const SizedBox(width: AppSpacing.sm),
                                Text('الخصم: ', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                                Text(coupon['discount'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.date_range_outlined, size: 14, color: AppColors.textLight),
                                const SizedBox(width: 4),
                                Text(
                                  'انتهى في: ${coupon['endDate']}',
                                  style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
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
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
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
    DateTime? startDate;
    DateTime? endDate;
    bool hasCondition = false;

    final laundryNames = _staffMembers
        .where((s) => s['type'] == 'مغسلة')
        .map((s) => s['name'].toString())
        .toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'إضافة عرض أو كوبون جديد',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
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
                  hintText: 'قيمة الخصم (مثال: 20% أو 50 ريال)',
                  controller: discountController,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'الفئة المستهدفة:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain),
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
                const Text(
                  'مدة العرض:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  startDate == null 
                                      ? 'تاريخ البدء' 
                                      : '${startDate!.year}/${startDate!.month.toString().padLeft(2, '0')}/${startDate!.day.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: startDate == null ? Colors.grey.shade600 : AppColors.textMain,
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
                            initialDate: endDate ?? DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setDialogState(() => endDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  endDate == null 
                                      ? 'تاريخ الانتهاء' 
                                      : '${endDate!.year}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.day.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: endDate == null ? Colors.grey.shade600 : AppColors.textMain,
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
                  title: const Text(
                    'تفعيل شرط على العرض',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain),
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
              child: const Text('إلغاء', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty || codeController.text.isEmpty) {
                  return;
                }

                // Validate discount field
                if (discountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يجب إدخال قيمة الخصم')),
                  );
                  return;
                }

                // Validate discount is a valid number
                final discountValue = double.tryParse(discountController.text.trim());
                if (discountValue == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('قيمة الخصم يجب أن تكون رقم صحيح')),
                  );
                  return;
                }

                // Check for duplicate codes
                final upperCode = codeController.text.toUpperCase();
                final isDuplicate = _coupons.any((c) => c['code'] == upperCode);
                if (isDuplicate) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('كود الكوبون موجود بالفعل')),
                  );
                  return;
                }

                setState(() {
                  _coupons.add({
                    'title': titleController.text,
                    'code': upperCode,
                    'discount': discountController.text,
                    'target': selectedTarget,
                    'status': 'نشط',
                    'startDate': startDate != null
                        ? '${startDate!.year}/${startDate!.month.toString().padLeft(2, '0')}/${startDate!.day.toString().padLeft(2, '0')}'
                        : 'غير محدد',
                    'endDate': endDate != null
                        ? '${endDate!.year}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.day.toString().padLeft(2, '0')}'
                        : 'غير محدد',
                    'minAmount': hasCondition ? minAmountController.text : null,
                  });
                });
                _logActivity(
                  'تم إضافة عرض/كوبون جديد ($upperCode) بخصم ${discountController.text}',
                  'add_coupon',
                  Icons.local_offer,
                  AppColors.primary,
                );
                titleController.dispose();
                codeController.dispose();
                discountController.dispose();
                minAmountController.dispose();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إضافة العرض بنجاح')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('إضافة العرض', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
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
    if (_selectedIndex >= 3) {
      _selectedIndex = 0;
    }
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
                    const SizedBox(width: AppSpacing.sm),
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
          SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeView(),
          _buildRegistrationsView(),
          _buildOffersView(),
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

