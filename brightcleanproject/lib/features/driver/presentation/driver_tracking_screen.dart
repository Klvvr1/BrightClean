import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DriverTrackingScreen extends StatelessWidget {
  final String taskId;

  const DriverTrackingScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تتبع مسار الطلب #$taskId')),
      body: Column(
        children: [
          // Map Placeholder
          Expanded(
            child: Container(
              color: Colors.grey.shade300,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 80, color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('خريطة جوجل (تتبع حي)'),
                  ],
                ),
              ),
            ),
          ),
          // Delivery Details
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('العميل: أحمد محمد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.secondary),
                    SizedBox(width: 8),
                    Expanded(child: Text('شارع الشيخ زايد، بالقرب من المركز المالي')),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.call),
                        label: const Text('اتصال'),
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('إنهاء التوصيل'),
                      ),
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
}
