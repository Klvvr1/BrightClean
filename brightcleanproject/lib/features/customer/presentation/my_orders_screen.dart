import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  Widget _buildStep(String title, bool isActive) {
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? AppColors.success : Colors.grey.shade300,
          child: isActive ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 10, color: isActive ? AppColors.textMain : Colors.grey)),
      ],
    );
  }

  Widget _buildOrderCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('طلب رقم #1024', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('15 أبريل 2026', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('غسيل ملابس - 5 قطع'),
            const SizedBox(height: 16),
            // Progress Tracker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStep('قيد الانتظار', true),
                const Expanded(child: Divider(color: AppColors.success, thickness: 2)),
                _buildStep('في الطريق', true),
                const Expanded(child: Divider(color: Colors.grey, thickness: 2)),
                _buildStep('قيد المعالجة', false),
                const Expanded(child: Divider(color: Colors.grey, thickness: 2)),
                _buildStep('جاهز', false),
                const Expanded(child: Divider(color: Colors.grey, thickness: 2)),
                _buildStep('تم التوصيل', false),
              ],
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
        appBar: AppBar(
          title: const Text('طلباتي'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الطلبات الحالية'),
              Tab(text: 'الطلبات السابقة'),
            ],
            indicatorColor: AppColors.lightBlue,
          ),
        ),
        body: TabBarView(
          children: [
            // Current Orders
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOrderCard(),
              ],
            ),
            // Past Orders
            const Center(child: Text('لا توجد طلبات سابقة')),
          ],
        ),
      ),
    );
  }
}
