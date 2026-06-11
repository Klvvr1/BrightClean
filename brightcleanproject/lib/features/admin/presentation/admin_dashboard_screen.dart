import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../core/enums/service_activation_status.dart';
import '../data/providers/admin_provider.dart';
import '../data/models/admin_service_model.dart';
import '../data/models/activation_request_model.dart';
import '../data/models/admin_offer_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/controllers/system_status_provider.dart';
import 'admin_profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

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

  static const List<String> _serviceCategoryLabels = [
    'ØºØ³ÙŠÙ„',
    'Ù…ÙØ±ÙˆØ´Ø§Øª Ù…Ù†Ø²Ù„ÙŠØ©',
    'Ø®Ø¯Ù…Ø§Øª Ù…Ù†Ø²Ù„ÙŠØ©',
    'ØºØ³ÙŠÙ„ Ù…Ø±ÙƒØ¨Ø§Øª',
  ];

  static const List<String> _serviceTypeLabels = [
    'ØºØ³ÙŠÙ„ ÙˆÙƒÙŠ',
    'ØªÙ†Ø¸ÙŠÙ Ø¬Ø§Ù',
    'ÙƒÙŠ ÙÙ‚Ø·',
    'Ø³ØªØ§Ø¦Ø±',
    'Ù…ÙØ§Ø±Ø´',
    'Ø¨Ø·Ø§Ù†ÙŠØ§Øª',
    'Ø³Ø¬Ø§Ø¯',
    'ØªÙ†Ø¸ÙŠÙ Ù…Ù†Ø²Ù„',
    'ØªÙ†Ø¸ÙŠÙ Ù…ÙƒÙŠÙØ§Øª',
    'ØªÙ†Ø¸ÙŠÙ Ø®Ø²Ø§Ù†Ø§Øª',
    'ØªÙ†Ø¸ÙŠÙ Ø£Ù„ÙˆØ§Ø­ Ø´Ù…Ø³ÙŠØ©',
    'ØºØ³ÙŠÙ„ Ø³ÙŠØ§Ø±Ø©',
    'ØºØ³ÙŠÙ„ Ø¯Ø±Ø§Ø¬Ø©',
  ];

  static const List<String> _pricingModelLabels = [
    'Ø¨Ø§Ù„Ù‚Ø·Ø¹Ø©',
    'Ø³Ø¹Ø± Ø«Ø§Ø¨Øª',
  ];

  static const List<String> _deliveryModelLabels = [
    'Ø§Ø³ØªÙ„Ø§Ù… ÙˆØªÙˆØµÙŠÙ„',
    'Ø²ÙŠØ§Ø±Ø© ÙÙ†ÙŠ',
  ];

  late TextEditingController _maintenanceMessageController;

  @override
  void initState() {
    super.initState();
    _maintenanceMessageController =
        TextEditingController(text: 'Ø§Ù„Ù†Ø¸Ø§Ù… ØªØ­Øª Ø§Ù„ØµÙŠØ§Ù†Ø©');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<SystemStatusProvider>(context, listen: false);
      final currentMessage =
          provider.maintenanceMessage ?? 'Ø§Ù„Ù†Ø¸Ø§Ù… ØªØ­Øª Ø§Ù„ØµÙŠØ§Ù†Ø©';
      _maintenanceMessageController.text = currentMessage;
      context.read<AdminProvider>().fetchSummary();
      context.read<AdminProvider>().fetchPendingUsers();
      context.read<AdminProvider>().fetchApprovedStaff();
      context.read<AdminProvider>().fetchServices();
      context.read<AdminProvider>().fetchServiceActivationRequests();
      context.read<AdminProvider>().fetchRecentOrders();
      context.read<AdminProvider>().fetchOffers();
      context.read<AdminProvider>().fetchNotificationHistory();
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

  final List<Map<String, dynamic>> _adminActivities = [];

  void _logActivity(String title, String type, IconData icon, Color color) {
    setState(() {
      _adminActivities.insert(0, {
        'title': title,
        'type': type,
        'time': 'Ø§Ù„Ø¢Ù†',
        'icon': icon,
        'color': color,
      });
    });
  }

  final List<String> _titles = [
    'Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠØ©',
    'Ø¥Ø¯Ø§Ø±Ø© Ø§Ù„ØªØ³Ø¬ÙŠÙ„Ø§Øª',
    'Ø§Ù„Ø¹Ø±ÙˆØ¶',
    'Ø­Ø³Ø§Ø¨ÙŠ'
  ];
  String get _currentTitle {
    if (_selectedIndex == 2) return 'Ø¥Ø¯Ø§Ø±Ø© Ø§Ù„Ø®Ø¯Ù…Ø§Øª';
    if (_selectedIndex > 2) return _titles[_selectedIndex - 1];
    return _titles[_selectedIndex];
  }

  void _showWarningDialog(String name) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ø¥Ø±Ø³Ø§Ù„ ØªØ­Ø°ÙŠØ± Ù„Ù€ $name'),
        content: CustomTextField(
          hintText: 'Ø§ÙƒØªØ¨ Ø³Ø¨Ø¨ Ø§Ù„ØªØ­Ø°ÙŠØ± Ù‡Ù†Ø§...',
          maxLines: 3,
          controller: reasonController,
        ),
        actions: [
          TextButton(
            onPressed: () {
              reasonController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Ø¥Ù„ØºØ§Ø¡'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text;
              reasonController.dispose();
              Navigator.pop(context);
              _logActivity(
                'ØªÙ… Ø¥Ø±Ø³Ø§Ù„ ØªØ­Ø°ÙŠØ± Ù„Ù€ "$name"${reason.isNotEmpty ? " Ø¨Ø³Ø¨Ø¨: $reason" : ""}',
                'warning',
                Icons.warning_amber_rounded,
                AppColors.warning,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'ØªÙ… Ø¥Ø±Ø³Ø§Ù„ Ø§Ù„ØªØ­Ø°ÙŠØ± Ù„Ù€ $name${reason.isNotEmpty ? ": $reason" : ""}')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Ø¥Ø±Ø³Ø§Ù„', style: TextStyle(color: Colors.white)),
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
            'ØªÙ… Ù‚Ø¨ÙˆÙ„ Ø·Ù„Ø¨ Ø§Ù†Ø¶Ù…Ø§Ù… ${request['type']} "${request['name']}" ÙˆØªÙØ¹ÙŠÙ„ Ø§Ù„Ø­Ø³Ø§Ø¨',
            request['type'] == 'Ù…ØºØ³Ù„Ø©' ? 'add_laundry' : 'add_driver',
            request['type'] == 'Ù…ØºØ³Ù„Ø©' ? Icons.business : Icons.person_add,
            AppColors.success,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ØªÙ… Ù‚Ø¨ÙˆÙ„ ${request['name']} Ø¨Ù†Ø¬Ø§Ø­')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  adminProvider.errorMessage ?? 'Ø­Ø¯Ø« Ø®Ø·Ø£ Ø£Ø«Ù†Ø§Ø¡ ØªÙØ¹ÙŠÙ„ Ø§Ù„Ø­Ø³Ø§Ø¨'),
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
      'ØªÙ… Ø±ÙØ¶ Ø·Ù„Ø¨ Ø§Ù†Ø¶Ù…Ø§Ù… "$name"',
      'reject_staff',
      Icons.highlight_off,
      AppColors.error,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ØªÙ… Ø±ÙØ¶ Ø·Ù„Ø¨ $name')),
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
              'ØªØ£ÙƒÙŠØ¯ Ø·Ø±Ø¯ Ù…Ù† Ø§Ù„Ù†Ø¸Ø§Ù…',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.error),
            ),
          ],
        ),
        content: Text(
          'Ù‡Ù„ Ø£Ù†Øª Ù…ØªØ£ÙƒØ¯ ØªÙ…Ø§Ù…Ø§Ù‹ Ù…Ù† Ø±ØºØ¨ØªÙƒ ÙÙŠ Ø·Ø±Ø¯ "$name" ($type) Ù…Ù† Ø§Ù„Ù†Ø¸Ø§Ù…ØŸ\n\nÙ‡Ø°Ø§ Ø§Ù„Ø¥Ø¬Ø±Ø§Ø¡ Ø³ÙŠÙ‚ÙˆÙ… Ø¨Ø¥Ù„ØºØ§Ø¡ ØªÙØ¹ÙŠÙ„ Ø­Ø³Ø§Ø¨Ù‡ ÙˆØ¥ÙŠÙ‚Ø§Ù ØµÙ„Ø§Ø­ÙŠØ© Ø§Ù„ÙˆØµÙˆÙ„ Ø§Ù„Ø®Ø§ØµØ© Ø¨Ù‡ Ø¨Ø§Ù„ÙƒØ§Ù…Ù„ ÙÙˆØ±Ø§Ù‹.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ø¥Ù„ØºØ§Ø¡',
                style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _staffMembers.removeWhere((m) => m['name'] == name);
              });
              _logActivity(
                'ØªÙ… Ø·Ø±Ø¯ $type "$name" ÙˆØ¥Ù„ØºØ§Ø¡ ØªÙØ¹ÙŠÙ„ Ø­Ø³Ø§Ø¨Ù‡ Ù…Ù† Ø§Ù„Ù†Ø¸Ø§Ù…',
                type == 'Ù…ØºØ³Ù„Ø©' ? 'remove_laundry' : 'remove_driver',
                Icons.person_remove,
                AppColors.error,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ØªÙ… Ø·Ø±Ø¯ $name ($type) Ù…Ù† Ø§Ù„Ù†Ø¸Ø§Ù… Ø¨Ù†Ø¬Ø§Ø­'),
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
            child: const Text('Ù†Ø¹Ù…ØŒ Ø·Ø±Ø¯ Ù…Ù† Ø§Ù„Ù†Ø¸Ø§Ù…',
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
          const Text('Ø§Ù„Ø¥ÙŠØ±Ø§Ø¯Ø§Øª Ø§Ù„Ù…Ø³Ø¬Ù„Ø©',
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
        const Text('Ø§Ù„Ø·Ù„Ø¨Ø§Øª Ø§Ù„Ù…Ø¨Ø§Ø´Ø±Ø©',
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
                        Text('Ø·Ù„Ø¨ #${order['id']}',
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
                'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø·Ù„Ø¨Ø§Øª Ø­Ø¯ÙŠØ«Ø©',
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
          fallback: 'Ø¹Ù…ÙŠÙ„',
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
                    Text('Ø·Ù„Ø¨ #$bookingId',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      laundryName.isEmpty
                          ? 'Ø¹Ù…ÙŠÙ„: $clientName'
                          : 'Ø¹Ù…ÙŠÙ„: $clientName â€¢ $laundryName',
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
                finalTotal > 0 ? '${finalTotal.toStringAsFixed(0)} Ø±.ÙŠ' : '-',
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
            'Ù†Ø¸Ø±Ø© Ø¹Ø§Ù…Ø©',
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
              _buildStatCard('Ø¥Ø¬Ù…Ø§Ù„ÙŠ Ø§Ù„Ø·Ù„Ø¨Ø§Øª', '${summary.totalOrders}',
                  Icons.shopping_bag_outlined, AppColors.primary,
                  delay: 0),
              _buildStatCard(
                  'Ø§Ù„Ø¥ÙŠØ±Ø§Ø¯Ø§Øª',
                  '${summary.totalRevenue.toStringAsFixed(0)} Ø±.ÙŠ',
                  Icons.account_balance_wallet_outlined,
                  AppColors.success,
                  delay: 100),
              _buildStatCard('Ø¹Ø¯Ø¯ Ø§Ù„Ø¹Ù…Ù„Ø§Ø¡', '${summary.customersCount}',
                  Icons.people_outline, AppColors.secondary,
                  delay: 200),
              _buildStatCard(
                'Ø§Ù„Ø³Ø§Ø¦Ù‚ÙŠÙ†',
                '$driversCount',
                Icons.drive_eta_outlined,
                AppColors.tertiary,
                subValue: 'Ø§Ù„Ù…Ø¹ØªÙ…Ø¯ÙŠÙ† ÙÙŠ Ø§Ù„Ù†Ø¸Ø§Ù…',
                delay: 300,
              ),
              _buildStatCard(
                'Ø§Ù„Ù…ØºØ§Ø³Ù„',
                '$laundriesCount',
                Icons.local_laundry_service_outlined,
                AppColors.warning,
                subValue: 'Ø§Ù„Ù…Ø´ØªØ±ÙƒØ© Ø­Ø§Ù„ÙŠØ§Ù‹',
                delay: 400,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildLiveOrdersSection(),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Ø§Ù„Ø·Ù„Ø¨Ø§Øª Ø§Ù„Ø£Ø®ÙŠØ±Ø©',
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
              'Ø³Ø¬Ù„ Ø¹Ù…Ù„ÙŠØ§Øª Ø§Ù„Ù…Ø´Ø±Ù Ø§Ù„Ø£Ø®ÙŠØ±Ø©',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
            if (_adminActivities.length > 5)
              TextButton(
                onPressed: _showAllActivitiesBottomSheet,
                child: const Text('Ø¹Ø±Ø¶ Ø§Ù„ÙƒÙ„',
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
                'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø¹Ù…Ù„ÙŠØ§Øª Ù…Ø³Ø¬Ù„Ø© Ø­Ø§Ù„ÙŠØ§Ù‹',
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
          'Ù„ÙˆØ­Ø© Ø§Ù„Ø¹Ù…Ù„ÙŠØ§Øª ÙˆØ§Ù„ØªØ´ØºÙŠÙ„',
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
                title: const Text('ÙˆØ¶Ø¹ Ø§Ù„ØµÙŠØ§Ù†Ø© Ù„Ù„Ù†Ø¸Ø§Ù…',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text(
                    'Ø¥ÙŠÙ‚Ø§Ù Ø§Ø³ØªÙ‚Ø¨Ø§Ù„ Ø·Ù„Ø¨Ø§Øª Ø§Ù„ØºØ³ÙŠÙ„ Ø§Ù„Ø¬Ø¯ÙŠØ¯Ø© ÙˆÙ…Ù†Ø¹ ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„',
                    style: TextStyle(fontSize: 12)),
                trailing: Switch(
                  value: !context.watch<SystemStatusProvider>().isLoginEnabled,
                  onChanged: (v) async {
                    try {
                      final message = v
                          ? (_maintenanceMessageController.text.isNotEmpty
                              ? _maintenanceMessageController.text
                              : "Ø§Ù„Ù†Ø¸Ø§Ù… ØªØ­Øª Ø§Ù„ØµÙŠØ§Ù†Ø©")
                          : null;
                      await context
                          .read<AdminProvider>()
                          .toggleSystemStatus(!v, message);
                      if (!mounted) return;
                      await context.read<SystemStatusProvider>().checkStatus();
                      _logActivity(
                        v
                            ? 'ØªÙ… ØªÙØ¹ÙŠÙ„ ÙˆØ¶Ø¹ ØµÙŠØ§Ù†Ø© Ø§Ù„Ù†Ø¸Ø§Ù…'
                            : 'ØªÙ… Ø¥Ù„ØºØ§Ø¡ ÙˆØ¶Ø¹ ØµÙŠØ§Ù†Ø© Ø§Ù„Ù†Ø¸Ø§Ù…',
                        v ? 'error' : 'success',
                        Icons.settings_suggest,
                        v ? AppColors.error : AppColors.success,
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ø­Ø¯Ø« Ø®Ø·Ø£: $e')),
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
                              'ØªÙ†Ø¨ÙŠÙ‡: ØªØ·Ø¨ÙŠÙ‚ Ø§Ù„Ø¹Ù…Ù„Ø§Ø¡ Ù…ØªÙˆÙ‚Ù Ø­Ø§Ù„ÙŠØ§Ù‹ ÙˆÙ„Ø§ ÙŠÙ…ÙƒÙ†Ù‡Ù… ØªÙ‚Ø¯ÙŠÙ… Ø·Ù„Ø¨Ø§Øª.',
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
                        hintText: 'Ø±Ø³Ø§Ù„Ø© Ø§Ù„ØµÙŠØ§Ù†Ø© Ø§Ù„ØªÙŠ Ø³ØªØ¸Ù‡Ø± Ù„Ù„Ø¹Ù…Ù„Ø§Ø¡...',
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
                                        Text('ØªÙ… Ø­ÙØ¸ Ø±Ø³Ø§Ù„Ø© Ø§Ù„ØµÙŠØ§Ù†Ø© Ø¨Ù†Ø¬Ø§Ø­!')),
                              );
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ø­Ø¯Ø« Ø®Ø·Ø£: $e')),
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
                          child: const Text('Ø­ÙØ¸ ÙˆÙ†Ø´Ø± Ø§Ù„Ø±Ø³Ø§Ù„Ø© Ù„Ù„Ø¹Ù…Ù„Ø§Ø¡',
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
                title: const Text('Ø¥Ø´Ø¹Ø§Ø±Ø§Øª Ø§Ù„Ù†Ø¸Ø§Ù… Ø§Ù„Ø°ÙƒÙŠØ©',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text(
                    'ØªÙ†Ø¨ÙŠÙ‡Ø§Øª ÙÙˆØ±ÙŠØ© Ù„Ù„Ù…Ø´Ø±Ù Ø¹Ù† Ø§Ù„Ù…Ø´Ø§ÙƒÙ„ Ø§Ù„ØªÙ‚Ù†ÙŠØ© ÙˆØ§Ù„Ø´ÙƒØ§ÙˆÙ‰',
                    style: TextStyle(fontSize: 12)),
                trailing: Switch(
                  value: _systemNotificationsEnabled,
                  onChanged: (v) {
                    setState(() {
                      _systemNotificationsEnabled = v;
                    });
                    _logActivity(
                      v
                          ? 'ØªÙ… ØªÙØ¹ÙŠÙ„ Ø¥Ø´Ø¹Ø§Ø±Ø§Øª Ø§Ù„Ù†Ø¸Ø§Ù… Ø§Ù„Ø°ÙƒÙŠØ©'
                          : 'ØªÙ… ØªØ¹Ø·ÙŠÙ„ Ø¥Ø´Ø¹Ø§Ø±Ø§Øª Ø§Ù„Ù†Ø¸Ø§Ù… Ø§Ù„Ø°ÙƒÙŠØ©',
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
                  'Ø³Ø¬Ù„ Ø¹Ù…Ù„ÙŠØ§Øª Ø§Ù„Ù…Ø´Ø±Ù Ø§Ù„ÙƒØ§Ù…Ù„',
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
              Tab(text: 'Ø·Ù„Ø¨Ø§Øª Ø§Ù„ØªÙˆØ¸ÙŠÙ'),
              Tab(text: 'Ø¥Ø¯Ø§Ø±Ø© Ø§Ù„Ù…ÙˆØ¸ÙÙŠÙ†'),
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
            'type': isLaundry ? 'Ù…ØºØ³Ù„Ø©' : 'Ø³Ø§Ø¦Ù‚',
            'phone': u.phoneNo ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±',
            'email': u.email,
            'location': 'ØºÙŠØ± Ù…ØªÙˆÙØ±',
            'commercialRegister': u.commercialRegister ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±',
            'nationalId': u.nationalIdNumber ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±',
            'licenseNumber': 'ØºÙŠØ± Ù…ØªÙˆÙØ±',
            'vehicleType': u.vehicleType ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±',
            'vehiclePlate': u.plateNumber ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±',
            'commercialRegisterImage': documentUrl('CommercialRegistration'),
            'nationalIdImage': documentUrl('NationalID'),
            'storefrontImage': null,
            'licenseImage': documentUrl('DriverLicense'),
            'vehicleImage': documentUrl('VehicleImage'),
          };
        }).toList();

        final laundries =
            mappedPending.where((r) => r['type'] == 'Ù…ØºØ³Ù„Ø©').toList();
        final drivers =
            mappedPending.where((r) => r['type'] == 'Ø³Ø§Ø¦Ù‚').toList();

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildSectionHeader('Ø§Ù„Ù…ØºØ§Ø³Ù„'),
            if (laundries.isEmpty)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('Ù„Ø§ ØªÙˆØ¬Ø¯ Ø·Ù„Ø¨Ø§Øª Ù…ØºØ§Ø³Ù„ Ø­Ø§Ù„ÙŠØ§Ù‹'))),
            ...laundries.map((r) => _buildRegistrationItem(r)),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionHeader('Ø§Ù„Ø³Ø§Ø¦Ù‚ÙŠÙ†'),
            if (drivers.isEmpty)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('Ù„Ø§ ØªÙˆØ¬Ø¯ Ø·Ù„Ø¨Ø§Øª Ù…Ù†Ø§Ø¯ÙŠØ¨ Ø­Ø§Ù„ÙŠØ§Ù‹'))),
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
                    staff['type'] == 'Ù…ØºØ³Ù„Ø©'
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
            const Text('Ø§Ù„Ù…Ø¹Ù„ÙˆÙ…Ø§Øª Ø§Ù„Ø´Ø®ØµÙŠØ© ÙˆØ§Ù„Ù…Ù‡Ù†ÙŠØ©',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  if (staff['type'] == 'Ù…ØºØ³Ù„Ø©') ...[
                    _buildDetailRow(
                        Icons.business, 'Ø§Ø³Ù… Ø§Ù„Ù…ØºØ³Ù„Ø©', staff['name']),
                    _buildDetailRow(Icons.person, 'Ø§Ø³Ù… Ø§Ù„Ù…Ø¯ÙŠØ± Ø§Ù„Ù…Ø³Ø¤ÙˆÙ„',
                        staff['managerName'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±'),
                    _buildDetailRow(Icons.phone, 'Ø±Ù‚Ù… Ø§Ù„Ù‡Ø§ØªÙ', staff['phone']),
                    _buildDetailRow(Icons.email, 'Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ',
                        staff['email'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±'),
                    _buildDetailRow(
                        Icons.location_on, 'Ø§Ù„Ù…ÙˆÙ‚Ø¹', staff['location']),
                    _buildDetailRow(Icons.badge, 'Ø±Ù‚Ù… Ø§Ù„Ù‡ÙˆÙŠØ© Ø§Ù„ÙˆØ·Ù†ÙŠØ© Ù„Ù„Ù…Ø¯ÙŠØ±',
                        staff['nationalId'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±'),
                    _buildDetailRow(
                        Icons.assignment,
                        'Ø±Ù‚Ù… Ø§Ù„Ø³Ø¬Ù„ Ø§Ù„ØªØ¬Ø§Ø±ÙŠ / Ø§Ù„ØªØ±Ø®ÙŠØµ',
                        staff['commercialRegister'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±'),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Ø§Ù„Ù…Ø³ØªÙ†Ø¯Ø§Øª ÙˆØ§Ù„ÙˆØ«Ø§Ø¦Ù‚ Ø§Ù„Ù…Ø±ÙÙˆØ¹Ø©',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildDocumentRow('ØµÙˆØ±Ø© Ø§Ù„Ø³Ø¬Ù„ Ø§Ù„ØªØ¬Ø§Ø±ÙŠ / Ø§Ù„ØªØ±Ø®ÙŠØµ',
                        staff['commercialRegisterImage']),
                    _buildDocumentRow(
                        'ØµÙˆØ±Ø© Ø§Ù„Ù‡ÙˆÙŠØ© Ø§Ù„ÙˆØ·Ù†ÙŠØ© Ù„Ù„Ù…Ø¯ÙŠØ±', staff['nationalIdImage']),
                    _buildDocumentRow(
                        'ØµÙˆØ±Ø© ÙˆØ§Ø¬Ù‡Ø©/Ù„ÙˆØ­Ø© Ø§Ù„Ù…ØºØ³Ù„Ø©', staff['storefrontImage']),
                  ] else ...[
                    _buildDetailRow(Icons.person, 'Ø§Ø³Ù… Ø§Ù„Ù…Ù†Ø¯ÙˆØ¨', staff['name']),
                    _buildDetailRow(Icons.phone, 'Ø±Ù‚Ù… Ø§Ù„Ù‡Ø§ØªÙ', staff['phone']),
                    _buildDetailRow(Icons.email, 'Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ',
                        staff['email'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±'),
                    _buildDetailRow(
                        Icons.location_on, 'Ø§Ù„Ù…ÙˆÙ‚Ø¹', staff['location']),
                    _buildDetailRow(Icons.badge, 'Ø±Ù‚Ù… Ø§Ù„Ù‡ÙˆÙŠØ© Ø§Ù„ÙˆØ·Ù†ÙŠØ©',
                        staff['nationalId'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±'),
                    _buildDetailRow(Icons.card_membership, 'Ø±Ù‚Ù… Ø±Ø®ØµØ© Ø§Ù„Ù‚ÙŠØ§Ø¯Ø©',
                        staff['licenseNumber'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±'),
                    _buildDetailRow(Icons.directions_car, 'Ù†ÙˆØ¹ Ù…Ø±ÙƒØ¨Ø© Ø§Ù„ØªÙˆØµÙŠÙ„',
                        staff['vehicleType'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±'),
                    _buildDetailRow(Icons.tag, 'Ø±Ù‚Ù… Ù„ÙˆØ­Ø© Ø§Ù„Ù…Ø±ÙƒØ¨Ø©',
                        staff['vehiclePlate'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±'),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Ø§Ù„Ù…Ø³ØªÙ†Ø¯Ø§Øª ÙˆØ§Ù„ÙˆØ«Ø§Ø¦Ù‚ Ø§Ù„Ù…Ø±ÙÙˆØ¹Ø©',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildDocumentRow(
                        'ØµÙˆØ±Ø© Ø±Ø®ØµØ© Ø§Ù„Ù‚ÙŠØ§Ø¯Ø© Ù„Ù„Ù…Ù†Ø¯ÙˆØ¨', staff['licenseImage']),
                    _buildDocumentRow('ØµÙˆØ±Ø© Ø§Ù„Ù‡ÙˆÙŠØ© Ø§Ù„ÙˆØ·Ù†ÙŠØ© Ù„Ù„Ù…Ù†Ø¯ÙˆØ¨',
                        staff['nationalIdImage']),
                    _buildDocumentRow(
                        'ØµÙˆØ±Ø© Ø§Ù„Ù…Ø±ÙƒØ¨Ø© Ø§Ù„Ø®Ø§ØµØ© Ø¨Ø§Ù„ØªÙˆØµÙŠÙ„', staff['vehicleImage']),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  const Text('Ø§Ù„Ø·Ù„Ø¨Ø§Øª Ø§Ù„Ø­Ø§Ù„ÙŠØ©/Ø§Ù„Ø³Ø§Ø¨Ù‚Ø©',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  const SizedBox(height: AppSpacing.sm),
                  if (staff['orders'] == null || staff['orders'].isEmpty)
                    const Text('Ù„Ø§ ØªÙˆØ¬Ø¯ Ø·Ù„Ø¨Ø§Øª Ù…Ø³Ø¬Ù„Ø© Ø­Ø§Ù„ÙŠØ§Ù‹',
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
                        const SnackBar(content: Text('Ø¬Ø§Ø±ÙŠ ÙØªØ­ Ø§Ù„Ø®Ø±ÙŠØ·Ø©...')),
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Ù…Ø´Ø§Ù‡Ø¯Ø© Ø§Ù„Ù…ÙˆÙ‚Ø¹'),
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
                    label: const Text('Ø·Ø±Ø¯ Ø§Ù„Ù…ÙˆØ¸Ù'),
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
            const Text('ØºÙŠØ± Ù…ØªÙˆÙØ±', style: TextStyle(color: Colors.red)),
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
          'Ø§Ù†Ù‚Ø± Ù„Ù„Ù…Ø¹Ø§ÙŠÙ†Ø© ÙˆØ§Ù„ØªÙƒØ¨ÙŠØ±',
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
                'Ø§Ø³ØªØ®Ø¯Ù… Ø¥ØµØ¨Ø¹ÙŠÙ† Ù„Ù„ØªÙƒØ¨ÙŠØ± ÙˆØ§Ù„ØªØ­Ø±ÙŠÙƒ ðŸ”Ž',
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
              hintText: 'Ø¨Ø­Ø« Ø¹Ù† Ù…ØºØ³Ù„Ø© Ø£Ùˆ Ù…Ù†Ø¯ÙˆØ¨...',
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
              _buildSectionHeader('Ø§Ù„Ù…ØºØ§Ø³Ù„ Ø§Ù„Ù…Ø¹ØªÙ…Ø¯Ø©'),
              ...filteredStaff.where((s) => s['type'] == 'Ù…ØºØ³Ù„Ø©').map((s) =>
                  _buildStaffItem(s['name'], s['type'], s['rating'],
                      staffData: s)),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionHeader('Ø§Ù„Ø³Ø§Ø¦Ù‚ÙŠÙ† Ø§Ù„Ù…Ø¹ØªÙ…Ø¯ÙŠÙ†'),
              ...filteredStaff.where((s) => s['type'] == 'Ø³Ø§Ø¦Ù‚').map((s) =>
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
                      'Ø¥Ø¯Ø§Ø±Ø© Ø§Ù„Ø®Ø¯Ù…Ø§Øª',
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
                    label: const Text('Ø¥Ø¶Ø§ÙØ© Ø®Ø¯Ù…Ø©'),
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
                  'Ø·Ù„Ø¨Ø§Øª ØªØ¹Ø¯ÙŠÙ„ Ø®Ø¯Ù…Ø§Øª Ø§Ù„Ù…ØºØ§Ø³Ù„',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'ØªØ­Ø¯ÙŠØ«',
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
                'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø·Ù„Ø¨Ø§Øª ØªØ¹Ø¯ÙŠÙ„ Ø®Ø¯Ù…Ø§Øª Ø­Ø§Ù„ÙŠØ§Ù‹',
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
    final actionText = isActivation ? 'ØªÙØ¹ÙŠÙ„' : 'Ø¥Ù„ØºØ§Ø¡ ØªÙØ¹ÙŠÙ„';
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
                          'Ø·Ù„Ø¨ $actionText',
                          style: TextStyle(
                            color: actionColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Text(
                        'Ø§Ø¶ØºØ· Ù„Ø¹Ø±Ø¶ Ø§Ù„ØªÙØ§ØµÙŠÙ„',
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
              child: const Text('Ø±ÙØ¶'),
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
              child: const Text('Ù‚Ø¨ÙˆÙ„'),
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
            'Ø§Ù„Ù…ØºØ§Ø³Ù„',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ø§Ø®ØªØ± Ù…ØºØ³Ù„Ø© Ù„ØªØ¹Ø¯ÙŠÙ„ Ø®Ø¯Ù…Ø§ØªÙ‡Ø§',
            style: TextStyle(color: AppColors.textLight, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            onChanged: (value) => setState(() => _laundrySearchQuery = value),
            decoration: InputDecoration(
              hintText: 'Ø¨Ø­Ø« Ø¨Ø§Ø³Ù… Ø§Ù„Ù…ØºØ³Ù„Ø©...',
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
              child: Center(child: Text('Ù„Ø§ ØªÙˆØ¬Ø¯ Ù…ØºØ§Ø³Ù„ Ù…Ø·Ø§Ø¨Ù‚Ø© Ù„Ù„Ø¨Ø­Ø«')),
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
                fallback: 'Ù…ØºØ³Ù„Ø© #$agentId',
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
                    'ID: $agentId â€¢ Ø§Ù„Ø®Ø¯Ù…Ø§Øª: ${serviceIds.length} â€¢ Ø§Ù„Ø­Ø§Ù„Ø©: ${storeClosed ? "Ù…ØºÙ„Ù‚Ø©" : "Ù…ØªØ§Ø­Ø©"}',
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
            'Ø§Ù„Ø®Ø¯Ù…Ø§Øª Ø§Ù„ØªÙŠ ØªÙ‚Ø¯Ù…Ù‡Ø§ Ø§Ù„Ù…ØºØ³Ù„Ø©',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_selectedLaundryAgentId == null)
            const Text('Ø§Ø®ØªØ± Ù…ØºØ³Ù„Ø© Ù…Ù† Ø§Ù„Ù‚Ø§Ø¦Ù…Ø© Ø¨Ø§Ù„Ø£Ø¹Ù„Ù‰ Ù„ØªØ¹Ø¯ÙŠÙ„ Ø®Ø¯Ù…Ø§ØªÙ‡Ø§')
          else if (_isLoadingLaundryServices)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (assignableServices.isEmpty)
              const Text('Ù„Ø§ ØªÙˆØ¬Ø¯ Ø®Ø¯Ù…Ø§Øª Ù…ÙØ¹Ù„Ø© Ù‚Ø§Ø¨Ù„Ø© Ù„Ù„Ø±Ø¨Ø· Ø­Ø§Ù„ÙŠØ§Ù‹')
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
                label: const Text('Ø­ÙØ¸ Ø®Ø¯Ù…Ø§Øª Ø§Ù„Ù…ØºØ³Ù„Ø©'),
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
            'ØªØµÙÙŠØ© Ø­Ø³Ø¨ Ø§Ù„Ø®Ø¯Ù…Ø©',
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
              labelText: 'Ø§Ù„Ø®Ø¯Ù…Ø©',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int>(
                value: -1,
                child: Text('ÙƒÙ„ Ø§Ù„Ø®Ø¯Ù…Ø§Øª'),
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
        'Ø¥Ø¯Ø§Ø±Ø© ÙƒØªØ§Ù„ÙˆØ¬ Ø§Ù„Ø®Ø¯Ù…Ø§Øª',
        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
      subtitle: const Text('Ø¥Ø¶Ø§ÙØ© ÙˆØªØ¹Ø¯ÙŠÙ„ ÙˆØªØ¹Ø·ÙŠÙ„ ÙˆØ­Ø°Ù Ø®Ø¯Ù…Ø§Øª Ø§Ù„ÙƒØªØ§Ù„ÙˆØ¬'),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: TextField(
            onChanged: (v) => setState(() => _serviceSearchQuery = v),
            decoration: InputDecoration(
              hintText: 'Ø¨Ø­Ø« Ø¹Ù† Ø®Ø¯Ù…Ø©...',
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
            label: const Text('Ø¥Ø¹Ø§Ø¯Ø© Ø§Ù„Ù…Ø­Ø§ÙˆÙ„Ø©'),
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
        child: const Center(child: Text('Ù„Ø§ ØªÙˆØ¬Ø¯ Ø®Ø¯Ù…Ø§Øª Ù…Ø·Ø§Ø¨Ù‚Ø©')),
      );
    }

    return Container(
      decoration: AppStyles.surface(context),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Ø§Ù„Ø®Ø¯Ù…Ø©')),
            DataColumn(label: Text('Ø§Ù„ØªØµÙ†ÙŠÙ')),
            DataColumn(label: Text('Ø§Ù„Ù†ÙˆØ¹')),
            DataColumn(label: Text('Ø§Ù„Ø³Ø¹Ø±')),
            DataColumn(label: Text('Ø§Ù„ØªØ³Ø¹ÙŠØ±')),
            DataColumn(label: Text('Ø§Ù„ØªÙ†ÙÙŠØ°')),
            DataColumn(label: Text('Ø§Ù„Ø­Ø§Ù„Ø©')),
            DataColumn(label: Text('Ø§Ù„Ù…ØºØ§Ø³Ù„')),
            DataColumn(label: Text('Ø¥Ø¬Ø±Ø§Ø¡Ø§Øª')),
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
        ? 'Ù…Ø­Ø°ÙˆÙØ©'
        : service.isAvailable
            ? 'Ù…ÙØ¹Ù„Ø©'
            : 'Ù…Ø¹Ø·Ù„Ø©';
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
          tooltip: 'ØªØ¹Ø¯ÙŠÙ„',
          onPressed:
              isBusy ? null : () => _showServiceFormDialog(service: service),
          icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
        ),
        IconButton(
          tooltip: service.isAvailable ? 'ØªØ¹Ø·ÙŠÙ„' : 'ØªÙØ¹ÙŠÙ„',
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
          tooltip: service.isDeleted ? 'Ø§Ø³ØªØ±Ø¬Ø§Ø¹' : 'Ø­Ø°Ù',
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
    return 'ØºÙŠØ± Ù…Ø¹Ø±ÙˆÙ';
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
            staff['type'] == 'مغسلة')
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
        SnackBar(content: Text('ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ Ø®Ø¯Ù…Ø§Øª Ø§Ù„Ù…ØºØ³Ù„Ø©: $e')),
      );
    }
  }

  Future<void> _saveLaundryServices() async {
    final agentId = _selectedLaundryAgentId;
    if (agentId == null) return;
    if (_selectedLaundryServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ÙŠØ¬Ø¨ Ø§Ø®ØªÙŠØ§Ø± Ø®Ø¯Ù…Ø© ÙˆØ§Ø­Ø¯Ø© Ø¹Ù„Ù‰ Ø§Ù„Ø£Ù‚Ù„')),
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
        const SnackBar(content: Text('ØªÙ… Ø­ÙØ¸ Ø®Ø¯Ù…Ø§Øª Ø§Ù„Ù…ØºØ³Ù„Ø© Ø¨Ù†Ø¬Ø§Ø­')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ØªØ¹Ø°Ø± Ø­ÙØ¸ Ø®Ø¯Ù…Ø§Øª Ø§Ù„Ù…ØºØ³Ù„Ø©: $e')),
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
          title: const Text('ØªÙØ§ØµÙŠÙ„ Ø·Ù„Ø¨ ØªØ¹Ø¯ÙŠÙ„ Ø§Ù„Ø®Ø¯Ù…Ø©'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRequestDetailRow('Ø§Ù„Ù…ØºØ³Ù„Ø©', request.agentName),
                  _buildRequestDetailRow('Ù…Ø¹Ø±Ù Ø§Ù„Ù…ØºØ³Ù„Ø©', '${request.agentId}'),
                  const Divider(height: 24),
                  const Text(
                    'Ø§Ù„Ø®Ø¯Ù…Ø§Øª Ø§Ù„Ø­Ø§Ù„ÙŠØ©',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildServiceNameWrap(
                    currentServices.map((service) => service.serviceName),
                    emptyText: 'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø®Ø¯Ù…Ø§Øª Ù…ÙØ¹Ù„Ø© Ø­Ø§Ù„ÙŠØ§Ù‹',
                  ),
                  const Divider(height: 24),
                  _buildRequestDetailRow(
                    isActivation
                        ? 'Ø§Ù„Ø®Ø¯Ù…Ø© Ø§Ù„ØªÙŠ Ø³ØªØªÙ… Ø¥Ø¶Ø§ÙØªÙ‡Ø§'
                        : 'Ø§Ù„Ø®Ø¯Ù…Ø© Ø§Ù„ØªÙŠ Ø³ØªØªÙ… Ø¥Ø²Ø§Ù„ØªÙ‡Ø§',
                    request.serviceName,
                  ),
                  _buildRequestDetailRow(
                    'Ù†ÙˆØ¹ Ø§Ù„Ø·Ù„Ø¨',
                    isActivation
                        ? 'Ø¥Ø¶Ø§ÙØ© / ØªÙØ¹ÙŠÙ„ Ø®Ø¯Ù…Ø©'
                        : 'Ø­Ø°Ù / Ø¥Ù„ØºØ§Ø¡ ØªÙØ¹ÙŠÙ„ Ø®Ø¯Ù…Ø©',
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Ø§Ù„Ø®Ø¯Ù…Ø§Øª Ø¨Ø¹Ø¯ Ø§Ù„Ù…ÙˆØ§ÙÙ‚Ø©',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildServiceNameWrap(
                    resultingServiceNames,
                    emptyText: 'Ù„Ù† ØªØ¨Ù‚Ù‰ Ø®Ø¯Ù…Ø§Øª Ù…ÙØ¹Ù„Ø©',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Ø¥ØºÙ„Ø§Ù‚'),
            ),
            TextButton(
              onPressed: provider.isActionLoading
                  ? null
                  : () {
                      Navigator.of(dialogContext).pop();
                      _rejectServiceActivationRequest(request);
                    },
              child: const Text('Ø±ÙØ¶'),
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
              child: const Text('Ù‚Ø¨ÙˆÙ„'),
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
        const SnackBar(content: Text('ØªÙ… Ù‚Ø¨ÙˆÙ„ Ø·Ù„Ø¨ ØªØ¹Ø¯ÙŠÙ„ Ø§Ù„Ø®Ø¯Ù…Ø©')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ØªØ¹Ø°Ø± Ù‚Ø¨ÙˆÙ„ Ø·Ù„Ø¨ ØªØ¹Ø¯ÙŠÙ„ Ø§Ù„Ø®Ø¯Ù…Ø©: $e')),
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
        const SnackBar(content: Text('ØªÙ… Ø±ÙØ¶ Ø·Ù„Ø¨ ØªØ¹Ø¯ÙŠÙ„ Ø§Ù„Ø®Ø¯Ù…Ø©')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ØªØ¹Ø°Ø± Ø±ÙØ¶ Ø·Ù„Ø¨ ØªØ¹Ø¯ÙŠÙ„ Ø§Ù„Ø®Ø¯Ù…Ø©: $e')),
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
            content: Text(isAvailable ? 'ØªÙ… ØªÙØ¹ÙŠÙ„ Ø§Ù„Ø®Ø¯Ù…Ø©' : 'ØªÙ… ØªØ¹Ø·ÙŠÙ„ Ø§Ù„Ø®Ø¯Ù…Ø©')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ØªØ¹Ø°Ø± ØªØºÙŠÙŠØ± Ø­Ø§Ù„Ø© Ø§Ù„Ø®Ø¯Ù…Ø©: $e')),
      );
    }
  }

  Future<void> _restoreService(AdminServiceModel service) async {
    try {
      await context.read<AdminProvider>().restoreService(service.serviceID);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('ØªÙ… Ø§Ø³ØªØ±Ø¬Ø§Ø¹ Ø§Ù„Ø®Ø¯Ù…Ø©. Ø§Ù„ØªÙØ¹ÙŠÙ„ ÙŠØ­ØªØ§Ø¬ Ø¥Ø¬Ø±Ø§Ø¡ Ù…Ù†ÙØµÙ„.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ØªØ¹Ø°Ø± Ø§Ø³ØªØ±Ø¬Ø§Ø¹ Ø§Ù„Ø®Ø¯Ù…Ø©: $e')),
      );
    }
  }

  void _confirmDeleteService(AdminServiceModel service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ø­Ø°Ù Ø§Ù„Ø®Ø¯Ù…Ø©'),
        content: Text(
          service.hasHistoricalUsage || service.linkedAgentCount > 0
              ? 'Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø¯Ù…Ø© Ù…Ø±ØªØ¨Ø·Ø© Ø¨Ø¨ÙŠØ§Ù†Ø§Øª Ø³Ø§Ø¨Ù‚Ø©ØŒ Ø³ÙŠØ·Ø¨Ù‚ Ø§Ù„Ù†Ø¸Ø§Ù… Ø§Ù„Ø­Ø°Ù Ø§Ù„Ø¢Ù…Ù† Ø¥Ù† Ù„Ø²Ù…. Ù‡Ù„ ØªØ±ÙŠØ¯ Ø§Ù„Ù…ØªØ§Ø¨Ø¹Ø©ØŸ'
              : 'Ù‡Ù„ ØªØ±ÙŠØ¯ Ø­Ø°Ù Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø¯Ù…Ø©ØŸ',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ø¥Ù„ØºØ§Ø¡'),
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
                  const SnackBar(content: Text('ØªÙ… Ø­Ø°Ù Ø§Ù„Ø®Ø¯Ù…Ø© Ø¨Ù†Ø¬Ø§Ø­')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('ØªØ¹Ø°Ø± Ø­Ø°Ù Ø§Ù„Ø®Ø¯Ù…Ø©: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Ø­Ø°Ù', style: TextStyle(color: Colors.white)),
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
          title: Text(service == null ? 'Ø¥Ø¶Ø§ÙØ© Ø®Ø¯Ù…Ø©' : 'ØªØ¹Ø¯ÙŠÙ„ Ø®Ø¯Ù…Ø©'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ø§Ø³Ù… Ø§Ù„Ø®Ø¯Ù…Ø©',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ø§Ù„Ø³Ø¹Ø±',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildServiceDropdown(
                  value: category,
                  label: 'Ø§Ù„ØªØµÙ†ÙŠÙ',
                  labels: _serviceCategoryLabels,
                  onChanged: (value) => setDialogState(() => category = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildServiceDropdown(
                  value: type,
                  label: 'Ø§Ù„Ù†ÙˆØ¹',
                  labels: _serviceTypeLabels,
                  onChanged: (value) => setDialogState(() => type = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildServiceDropdown(
                  value: pricingModel,
                  label: 'Ø·Ø±ÙŠÙ‚Ø© Ø§Ù„ØªØ³Ø¹ÙŠØ±',
                  labels: _pricingModelLabels,
                  onChanged: (value) =>
                      setDialogState(() => pricingModel = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildServiceDropdown(
                  value: deliveryModel,
                  label: 'Ø·Ø±ÙŠÙ‚Ø© Ø§Ù„ØªÙ†ÙÙŠØ°',
                  labels: _deliveryModelLabels,
                  onChanged: (value) =>
                      setDialogState(() => deliveryModel = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ø§Ù„Ø®Ø¯Ù…Ø© Ù…ØªØ§Ø­Ø© Ù„Ù„Ø¹Ù…Ù„Ø§Ø¡'),
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
              child: const Text('Ø¥Ù„ØºØ§Ø¡'),
            ),
            ElevatedButton(
              onPressed: () async {
                final price = double.tryParse(priceController.text.trim());
                if (nameController.text.trim().isEmpty ||
                    price == null ||
                    price < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ØªØ£ÙƒØ¯ Ù…Ù† Ø§Ø³Ù… Ø§Ù„Ø®Ø¯Ù…Ø© ÙˆØ§Ù„Ø³Ø¹Ø±')),
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
                          ? 'ØªÙ…Øª Ø¥Ø¶Ø§ÙØ© Ø§Ù„Ø®Ø¯Ù…Ø© Ø¨Ù†Ø¬Ø§Ø­'
                          : 'ØªÙ… ØªØ¹Ø¯ÙŠÙ„ Ø§Ù„Ø®Ø¯Ù…Ø© Ø¨Ù†Ø¬Ø§Ø­'),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('ØªØ¹Ø°Ø± Ø­ÙØ¸ Ø§Ù„Ø®Ø¯Ù…Ø©: $e')),
                  );
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Ø­ÙØ¸', style: TextStyle(color: Colors.white)),
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
        'phone': staff['phoneNo'] ?? staff['PhoneNo'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±',
        'email': staff['email'] ?? staff['Email'] ?? '',
        'location': 'ØºÙŠØ± Ù…ØªÙˆÙØ±',
        'commercialRegister': staff['commercialRegister'] ??
            staff['CommercialRegister'] ??
            'ØºÙŠØ± Ù…ØªÙˆÙØ±',
        'nationalId': staff['nationalIDNumber'] ??
            staff['nationalIdNumber'] ??
            staff['NationalIDNumber'] ??
            'ØºÙŠØ± Ù…ØªÙˆÙØ±',
        'licenseNumber': 'ØºÙŠØ± Ù…ØªÙˆÙØ±',
        'vehicleType': staff['vehicleType']?.toString() ??
            staff['VehicleType']?.toString() ??
            'ØºÙŠØ± Ù…ØªÙˆÙØ±',
        'vehiclePlate':
            staff['plateNumber'] ?? staff['PlateNumber'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±',
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
      if (n.contains('Ø³Ø¹ÙŠØ¯') && n.contains('Ø¹Ø¨Ø¯Ø§Ù„Ù„Ù‡')) {
        type = 'ØªÙƒØªÙƒ';
      } else if (n.contains('Ø®Ø§Ù„Ø¯')) {
        type = 'Ø¯Ø±Ø§Ø¬Ø©';
      } else if (n.contains('ÙŠØ§Ø³ÙŠÙ†')) {
        type = 'Ø³ÙŠØ§Ø±Ø©';
      } else if (n.contains('ØµØ§Ù„Ø­')) {
        type = 'ØªÙƒØªÙƒ';
      } else if (n.contains('Ø¹Ù…Ø±')) {
        type = 'ØªÙƒØªÙƒ';
      }
    }
    if (type == null) return Icons.directions_car;
    final typeLower = type.toLowerCase();
    if (typeLower.contains('Ø¯Ø±Ø§Ø¬Ø©') ||
        typeLower.contains('Ù†Ø§Ø±ÙŠØ©') ||
        typeLower.contains('Ù…ÙˆØªÙˆØ±') ||
        typeLower.contains('motorcycle') ||
        typeLower.contains('bike') ||
        typeLower.contains('wheeler')) {
      return Icons.motorcycle;
    }
    if (typeLower.contains('ØªÙƒ') ||
        typeLower.contains('ØªÙƒØªÙƒ') ||
        typeLower.contains('rickshaw') ||
        typeLower.contains('tuk')) {
      return Icons.electric_rickshaw;
    }
    if (typeLower.contains('Ø³ÙŠØ§Ø±Ø©') ||
        typeLower.contains('Ù…Ø±ÙƒØ¨Ø©') ||
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
            request['type'] == 'Ù…ØºØ³Ù„Ø©'
                ? Icons.local_laundry_service
                : _getVehicleIcon(request['vehicleType'], request['name']),
            color: AppColors.tertiary,
          ),
        ),
        title: Text(request['name'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Ø§Ù„Ù‡Ø§ØªÙ: ${request['phone']}'),
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
                    request['type'] == 'Ù…ØºØ³Ù„Ø©'
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
                        request['type'] == 'Ù…ØºØ³Ù„Ø©'
                            ? 'Ø·Ù„Ø¨ Ø§Ù†Ø¶Ù…Ø§Ù… Ù…ØºØ³Ù„Ø© Ø¬Ø¯ÙŠØ¯Ø©'
                            : 'Ø·Ù„Ø¨ Ø§Ù†Ø¶Ù…Ø§Ù… Ù…Ù†Ø¯ÙˆØ¨ ØªÙˆØµÙŠÙ„',
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
              'Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø­Ø³Ø§Ø¨ Ø§Ù„Ø´Ø®ØµÙŠØ© ÙˆØ§Ù„ØªØ³Ø¬ÙŠÙ„',
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
                  if (request['type'] == 'Ù…ØºØ³Ù„Ø©') ...[
                    _buildDetailRow(
                        Icons.business, 'Ø§Ø³Ù… Ø§Ù„Ù…ØºØ³Ù„Ø©', request['name']),
                    _buildDetailRow(Icons.person, 'Ø§Ø³Ù… Ø§Ù„Ù…Ø¯ÙŠØ± Ø§Ù„Ù…Ø³Ø¤ÙˆÙ„',
                        request['managerName'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±'),
                    _buildDetailRow(
                        Icons.phone, 'Ø±Ù‚Ù… Ù‡Ø§ØªÙ Ø§Ù„Ù…Ø¯ÙŠØ±', request['phone']),
                    _buildDetailRow(Icons.email, 'Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ Ù„Ù„Ù…Ø¯ÙŠØ±',
                        request['email'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±'),
                    _buildDetailRow(Icons.location_on, 'Ø¹Ù†ÙˆØ§Ù† Ø§Ù„Ù…ØºØ³Ù„Ø©',
                        request['location']),
                    _buildDetailRow(Icons.badge, 'Ø±Ù‚Ù… Ø§Ù„Ù‡ÙˆÙŠØ© Ø§Ù„ÙˆØ·Ù†ÙŠØ© Ù„Ù„Ù…Ø¯ÙŠØ±',
                        request['nationalId'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±'),
                    _buildDetailRow(
                        Icons.assignment,
                        'Ø±Ù‚Ù… Ø§Ù„Ø³Ø¬Ù„ Ø§Ù„ØªØ¬Ø§Ø±ÙŠ / Ø§Ù„ØªØ±Ø®ÙŠØµ',
                        request['commercialRegister'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±'),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Ø§Ù„Ù…Ø³ØªÙ†Ø¯Ø§Øª ÙˆØ§Ù„ÙˆØ«Ø§Ø¦Ù‚ Ø§Ù„Ù…Ø±ÙÙˆØ¹Ø©',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildDocumentRow('ØµÙˆØ±Ø© Ø§Ù„Ø³Ø¬Ù„ Ø§Ù„ØªØ¬Ø§Ø±ÙŠ / Ø§Ù„ØªØ±Ø®ÙŠØµ',
                        request['commercialRegisterImage']),
                    _buildDocumentRow('ØµÙˆØ±Ø© Ø§Ù„Ù‡ÙˆÙŠØ© Ø§Ù„ÙˆØ·Ù†ÙŠØ© Ù„Ù„Ù…Ø¯ÙŠØ±',
                        request['nationalIdImage']),
                    _buildDocumentRow(
                        'ØµÙˆØ±Ø© ÙˆØ§Ø¬Ù‡Ø©/Ù„ÙˆØ­Ø© Ø§Ù„Ù…ØºØ³Ù„Ø©', request['storefrontImage']),
                  ] else ...[
                    _buildDetailRow(
                        Icons.person, 'Ø§Ø³Ù… Ø§Ù„Ù…Ù†Ø¯ÙˆØ¨', request['name']),
                    _buildDetailRow(
                        Icons.phone, 'Ø±Ù‚Ù… Ù‡Ø§ØªÙ Ø§Ù„Ù…Ù†Ø¯ÙˆØ¨', request['phone']),
                    _buildDetailRow(Icons.email, 'Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ Ù„Ù„Ù…Ù†Ø¯ÙˆØ¨',
                        request['email'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±'),
                    _buildDetailRow(Icons.location_on, 'Ø¹Ù†ÙˆØ§Ù† Ø§Ù„Ø³ÙƒÙ† Ø§Ù„Ø­Ø§Ù„ÙŠ',
                        request['location']),
                    _buildDetailRow(Icons.badge, 'Ø±Ù‚Ù… Ø§Ù„Ù‡ÙˆÙŠØ© Ø§Ù„ÙˆØ·Ù†ÙŠØ©',
                        request['nationalId'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±'),
                    _buildDetailRow(Icons.card_membership, 'Ø±Ù‚Ù… Ø±Ø®ØµØ© Ø§Ù„Ù‚ÙŠØ§Ø¯Ø©',
                        request['licenseNumber'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±'),
                    _buildDetailRow(Icons.directions_car, 'Ù†ÙˆØ¹ Ù…Ø±ÙƒØ¨Ø© Ø§Ù„ØªÙˆØµÙŠÙ„',
                        request['vehicleType'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±'),
                    _buildDetailRow(Icons.tag, 'Ø±Ù‚Ù… Ù„ÙˆØ­Ø© Ø§Ù„Ù…Ø±ÙƒØ¨Ø©',
                        request['vehiclePlate'] ?? 'ØºÙŠØ± Ù…ØªÙˆÙØ±'),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Ø§Ù„Ù…Ø³ØªÙ†Ø¯Ø§Øª ÙˆØ§Ù„ÙˆØ«Ø§Ø¦Ù‚ Ø§Ù„Ù…Ø±ÙÙˆØ¹Ø©',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildDocumentRow(
                        'ØµÙˆØ±Ø© Ø±Ø®ØµØ© Ø§Ù„Ù‚ÙŠØ§Ø¯Ø© Ù„Ù„Ù…Ù†Ø¯ÙˆØ¨', request['licenseImage']),
                    _buildDocumentRow('ØµÙˆØ±Ø© Ø§Ù„Ù‡ÙˆÙŠØ© Ø§Ù„ÙˆØ·Ù†ÙŠØ© Ù„Ù„Ù…Ù†Ø¯ÙˆØ¨',
                        request['nationalIdImage']),
                    _buildDocumentRow('ØµÙˆØ±Ø© Ø§Ù„Ù…Ø±ÙƒØ¨Ø© Ø§Ù„Ø®Ø§ØµØ© Ø¨Ø§Ù„ØªÙˆØµÙŠÙ„',
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
                    label: const Text('Ù‚Ø¨ÙˆÙ„ Ø§Ù„Ø·Ù„Ø¨ ÙˆØªÙØ¹ÙŠÙ„ Ø§Ù„Ø­Ø³Ø§Ø¨',
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
                    label: const Text('Ø±ÙØ¶ Ø§Ù„Ø·Ù„Ø¨',
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
              type == 'Ù…ØºØ³Ù„Ø©'
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
              tooltip: 'Ø¥Ø±Ø³Ø§Ù„ ØªØ­Ø°ÙŠØ±',
            ),
            TextButton(
              onPressed: () => _dismissStaff(name, type),
              child:
                  const Text('Ø·Ø±Ø¯', style: TextStyle(color: AppColors.error)),
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
              Tab(text: 'العروض'),
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
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, _) {
        final activeOffers = adminProvider.offers
            .where((offer) => offer.isValid && !_isOfferExpired(offer))
            .toList();
        final expiredOffers = adminProvider.offers
            .where((offer) => !offer.isValid || _isOfferExpired(offer))
            .toList();

        return RefreshIndicator(
          onRefresh: () => adminProvider.fetchOffers(),
          child: ListView(
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
                'إرسال إشعار',
                'أرسل رسالة للمستخدمين حسب الفئة المختارة',
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
              if (adminProvider.isLoading && adminProvider.offers.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (activeOffers.isEmpty)
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
                ...activeOffers.map((offer) => _buildOfferCard(offer)),
              if (expiredOffers.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'العروض المنتهية',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...expiredOffers.map((offer) => Opacity(
                      opacity: 0.6,
                      child: _buildOfferCard(offer),
                    )),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfferCard(AdminOfferModel offer) {
    final isGlobal = offer.scope != 'SpecificAgent';
    return Container(
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
          color: isGlobal
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.warning.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isGlobal ? AppColors.primary : AppColors.warning)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGlobal ? Icons.confirmation_number_outlined : Icons.storefront,
              color: isGlobal ? AppColors.primary : AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('كود العرض: ${offer.offerCode}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text('الخصم: ${offer.discountLabel}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                        fontSize: 13)),
                const SizedBox(height: 4),
                Text('النطاق: ${offer.targetLabel}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  'المدة: من ${_formatAdminDate(offer.startDate)} إلى ${_formatAdminDate(offer.endDate)}',
                  style:
                      const TextStyle(color: AppColors.textLight, fontSize: 12),
                ),
                if (offer.minOrderValue != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'الحد الأدنى: ${offer.minOrderValue!.toStringAsFixed(0)} ريال',
                    style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
                if (offer.maxUsageCount != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'الاستخدام: ${offer.usageCount}/${offer.maxUsageCount}',
                    style: const TextStyle(
                        color: AppColors.textLight, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.error, size: 20),
            onPressed: () async {
              try {
                await context.read<AdminProvider>().deleteOffer(offer.offerID);
                _logActivity(
                  'تم حذف العرض (${offer.offerCode})',
                  'remove_coupon',
                  Icons.delete_outline,
                  AppColors.error,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف العرض بنجاح')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('فشل حذف العرض: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationHistoryView() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, _) {
        final history = adminProvider.notificationHistory;
        if (adminProvider.isLoading && history.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (history.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد إشعارات مرسلة حالياً',
              style: TextStyle(color: AppColors.textLight),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => adminProvider.fetchNotificationHistory(),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: history.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final note = history[index] as Map;
              final date =
                  DateTime.tryParse((note['date'] ?? '').toString());
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.notifications_active,
                        color: Colors.white, size: 20),
                  ),
                  title: Text((note['title'] ?? '').toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((note['message'] ?? '').toString()),
                      const SizedBox(height: 4),
                      Text(
                        '${date == null ? '' : _formatAdminDate(date)} - المستلمون: ${note['recipientCount'] ?? 0}',
                        style: const TextStyle(
                            color: AppColors.textLight, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showNotificationDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String selectedTargetRole = 'Client';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('إرسال إشعار'),
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
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: selectedTargetRole,
                decoration: const InputDecoration(labelText: 'المستلمون'),
                items: const [
                  DropdownMenuItem(value: 'Client', child: Text('العملاء')),
                  DropdownMenuItem(
                      value: 'DeliveryStaff', child: Text('المناديب')),
                  DropdownMenuItem(
                      value: 'LaundryAgent', child: Text('وكلاء المغاسل')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedTargetRole = value);
                  }
                },
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
              onPressed: () async {
                final title = titleController.text.trim();
                final body = bodyController.text.trim();
                if (title.isEmpty || body.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('الرجاء إدخال عنوان ونص الإشعار')),
                  );
                  return;
                }
                final adminProvider = context.read<AdminProvider>();
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await adminProvider.sendNotification({
                    'title': title,
                    'message': body,
                    'targetRole': selectedTargetRole,
                  });
                  titleController.dispose();
                  bodyController.dispose();
                  if (!mounted) return;
                  navigator.pop();
                  _logActivity(
                    'تم إرسال إشعار: "$title"',
                    'send_notification',
                    Icons.notifications_active,
                    AppColors.primary,
                  );
                  messenger.showSnackBar(
                    const SnackBar(content: Text('تم إرسال الإشعار بنجاح')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('فشل إرسال الإشعار: $e')),
                  );
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child:
                  const Text('إرسال الآن', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  void _showCreateOfferDialog() {
    final codeController = TextEditingController();
    final discountController = TextEditingController();
    final minAmountController = TextEditingController();
    final maxUsageController = TextEditingController();
    String selectedTarget = 'all';
    String selectedOfferType = 'Percentage';
    DateTime? startDate;
    DateTime? endDate;
    bool hasCondition = false;
    bool sendNotification = true;

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final approvedStaff = _mapApprovedStaff(adminProvider.approvedStaff);
    final laundryOptions = approvedStaff
        .where((s) => s['type'] == 'مغسلة')
        .map((s) => {
              'id': s['id'],
              'name': s['name'].toString(),
            })
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
                  hintText: 'كود الخصم (مثال: SUMMER25)',
                  controller: codeController,
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  hintText: 'قيمة الخصم',
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
                DropdownButtonFormField<String>(
                  initialValue: selectedOfferType,
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
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: selectedTarget,
                  decoration: const InputDecoration(labelText: 'نطاق العرض'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: 'all',
                      child: Text('كل المغاسل'),
                    ),
                    ...laundryOptions.map((laundry) => DropdownMenuItem<String>(
                          value: laundry['id'].toString(),
                          child: Text(laundry['name'].toString()),
                        )),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedTarget = val);
                    }
                  },
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
                        child: _buildDatePickerBox(
                          startDate == null
                              ? 'تاريخ البدء'
                              : _formatAdminDate(startDate!),
                          startDate != null,
                          theme,
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
                        child: _buildDatePickerBox(
                          endDate == null
                              ? 'تاريخ الانتهاء'
                              : _formatAdminDate(endDate!),
                          endDate != null,
                          theme,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  title: Text(
                    'تفعيل شرط الحد الأدنى',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface),
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
                    hintText: 'الحد الأدنى لقيمة الطلب بالريال',
                    controller: minAmountController,
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                CustomTextField(
                  hintText: 'عدد مرات الاستخدام (اختياري)',
                  controller: maxUsageController,
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  title: Text(
                    'إرسال إشعار للعملاء',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface),
                  ),
                  value: sendNotification,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setDialogState(() => sendNotification = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                codeController.dispose();
                discountController.dispose();
                minAmountController.dispose();
                maxUsageController.dispose();
                Navigator.pop(context);
              },
              child: const Text('إلغاء',
                  style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () async {
                final discountValue =
                    double.tryParse(discountController.text.trim());
                final maxUsage = maxUsageController.text.trim().isEmpty
                    ? null
                    : int.tryParse(maxUsageController.text.trim());
                final minAmount = hasCondition
                    ? double.tryParse(minAmountController.text.trim())
                    : null;
                if (codeController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الرجاء إدخال كود الخصم')),
                  );
                  return;
                }
                if (discountValue == null || discountValue <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('قيمة الخصم يجب أن تكون رقماً صالحاً')),
                  );
                  return;
                }
                if (selectedOfferType == 'Percentage' &&
                    discountValue > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('النسبة المئوية يجب أن تكون بين 1 و 100')),
                  );
                  return;
                }
                if (startDate == null || endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('يجب تحديد تاريخ البدء والانتهاء')),
                  );
                  return;
                }
                if (!endDate!.isAfter(startDate!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('تاريخ الانتهاء يجب أن يكون بعد تاريخ البدء')),
                  );
                  return;
                }
                if (hasCondition && minAmount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('الحد الأدنى يجب أن يكون رقماً صالحاً')),
                  );
                  return;
                }
                if (maxUsageController.text.trim().isNotEmpty &&
                    (maxUsage == null || maxUsage <= 0)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('عدد مرات الاستخدام يجب أن يكون رقماً صالحاً')),
                  );
                  return;
                }

                final laundryAgentId =
                    selectedTarget == 'all' ? null : int.tryParse(selectedTarget);
                final adminProvider = context.read<AdminProvider>();
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  await adminProvider.createOffer({
                    'offerCode': codeController.text.trim().toUpperCase(),
                    'type': selectedOfferType == 'Percentage' ? 0 : 1,
                    'scope': selectedTarget == 'all' ? 0 : 1,
                    'discountValue': discountValue,
                    'startDate': startDate!.toIso8601String(),
                    'endDate': DateTime(endDate!.year, endDate!.month,
                            endDate!.day, 23, 59, 59)
                        .toIso8601String(),
                    'minOrderValue': minAmount,
                    'maxUsageCount': maxUsage,
                    'laundryAgentID': laundryAgentId,
                    'sendNotificationToClients': sendNotification,
                  });
                  final code = codeController.text.trim().toUpperCase();
                  codeController.dispose();
                  discountController.dispose();
                  minAmountController.dispose();
                  maxUsageController.dispose();
                  if (!mounted) return;
                  navigator.pop();
                  _logActivity(
                    'تم إضافة عرض جديد ($code)',
                    'add_coupon',
                    Icons.local_offer,
                    AppColors.primary,
                  );
                  messenger.showSnackBar(
                    const SnackBar(content: Text('تم إضافة العرض بنجاح')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('فشل إنشاء العرض: $e')),
                  );
                }
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

  Widget _buildDatePickerBox(String label, bool hasValue, ThemeData theme) {
    return Container(
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
              label,
              style: TextStyle(
                fontSize: 11,
                color: hasValue ? theme.colorScheme.onSurface : Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAdminDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  bool _isOfferExpired(AdminOfferModel offer) {
    return DateTime.now().isAfter(offer.endDate);
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

