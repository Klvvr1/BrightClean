import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class OrderData {
  static List<Map<String, dynamic>> currentOrders = [
    {
      'orderId': '1025',
      'date': '16 أبريل 2026',
      'details': 'تنظيف سجاد - 2 قطعة',
      'status': 'قيد الانتظار',
      'statusColor': AppColors.warning,
      'activeStepIndex': 0,
    },
    {
      'orderId': '1024',
      'date': '15 أبريل 2026',
      'details': 'غسيل ملابس - 5 قطع',
      'status': 'في الطريق',
      'statusColor': AppColors.warning,
      'activeStepIndex': 1,
    },
  ];
}

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  Widget _buildStep(String title, bool isActive, {Color activeColor = AppColors.success}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? activeColor : Colors.grey.shade300,
          child: isActive ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 10, color: isActive ? AppColors.textMain : Colors.grey)),
      ],
    );
  }

  Widget _buildOrderCard({
    required String orderId,
    required String date,
    required String details,
    required String status,
    required Color statusColor,
    bool showTracker = true,
    int activeStepIndex = 1,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('طلب رقم #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(details, style: const TextStyle(color: AppColors.textMain, fontSize: 14)),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            if (showTracker) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // Progress Tracker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStep('قيد الانتظار', activeStepIndex >= 0, activeColor: AppColors.success),
                  Expanded(child: Divider(color: activeStepIndex >= 1 ? AppColors.success : Colors.grey, thickness: 2)),
                  _buildStep('في الطريق', activeStepIndex >= 1, activeColor: AppColors.success),
                  Expanded(child: Divider(color: activeStepIndex >= 2 ? AppColors.success : Colors.grey, thickness: 2)),
                  _buildStep('قيد المعالجة', activeStepIndex >= 2, activeColor: AppColors.success),
                  Expanded(child: Divider(color: activeStepIndex >= 3 ? AppColors.success : Colors.grey, thickness: 2)),
                  _buildStep('جاهز', activeStepIndex >= 3, activeColor: AppColors.success),
                  Expanded(child: Divider(color: activeStepIndex >= 4 ? AppColors.success : Colors.grey, thickness: 2)),
                  _buildStep('تم التوصيل', activeStepIndex >= 4, activeColor: AppColors.success),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required String title, required String subtitle, required IconData icon}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.pushReplacement('/customer_home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('اطلب الآن', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('طلباتي', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: 'الطلبات الحالية'),
              Tab(text: 'الطلبات السابقة'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Current Orders
            OrderData.currentOrders.isEmpty 
              ? _buildEmptyState(
                  context,
                  title: 'لا توجد طلبات حالية',
                  subtitle: 'قم بطلب خدمة جديدة لتبدأ التجربة.',
                  icon: Icons.receipt_rounded,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: OrderData.currentOrders.length,
                  itemBuilder: (context, index) {
                    final order = OrderData.currentOrders[index];
                    return _buildOrderCard(
                      orderId: order['orderId'],
                      date: order['date'],
                      details: order['details'],
                      status: order['status'],
                      statusColor: order['statusColor'],
                      activeStepIndex: order['activeStepIndex'],
                      showTracker: true,
                    );
                  },
                ),
            // Past Orders (Empty State Example)
            _buildEmptyState(
              context,
              title: 'لا توجد طلبات سابقة',
              subtitle: 'يبدو أنك لم تقم بأي طلبات في الماضي. اطلب الآن لتجربة خدماتنا المميزة.',
              icon: Icons.receipt_long_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
