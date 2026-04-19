import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  bool _isOnline = false;

  Widget _buildTaskCard(BuildContext context) {
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
                Text('توصيل طلب #1026', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('منذ 5 د', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.trip_origin, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Text('الاستلام: المغسلة الذهبية (1.2 كم)'),
              ],
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.secondary),
                SizedBox(width: 8),
                Text('التسليم: منزل العميل (3.5 كم)'),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/driver_tracking/1026'),
              child: const Text('بدء التوصيل'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة السائق'),
        actions: [
          Row(
            children: [
              Text(_isOnline ? 'متاح' : 'غير متاح', style: const TextStyle(fontWeight: FontWeight.bold)),
              Switch(
                value: _isOnline,
                activeColor: AppColors.success,
                onChanged: (v) => setState(() => _isOnline = v),
              ),
            ],
          ),
        ],
      ),
      body: _isOnline
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Earnings Summary
                Card(
                  color: AppColors.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('أرباح اليوم', style: TextStyle(color: Colors.white, fontSize: 18)),
                        Text('120 درهم', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('المهام المتاحة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTaskCard(context),
                _buildTaskCard(context),
              ],
            )
          : const Center(
              child: Text(
                'أنت الآن غير متاح.\nقم بتفعيل الحالة لتلقي الطلبات.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
    );
  }
}
