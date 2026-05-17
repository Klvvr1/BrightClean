import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock notifications
    final List<Map<String, String>> notifications = [
      {
        'title': 'تم استلام طلبك',
        'body': 'لقد بدأنا العمل على طلب غسيل السجاد الخاص بك.',
        'time': 'منذ 10 دقائق',
        'icon': 'receipt',
      },
      {
        'title': 'السائق في الطريق',
        'body': 'السائق أحمد في طريقه لاستلام الملابس من موقعك.',
        'time': 'منذ ساعة',
        'icon': 'local_shipping',
      },
      {
        'title': 'عرض خاص! ✨',
        'body': 'استخدم الكود BC20 واحصل على خصم 20% على طلبك القادم.',
        'time': 'منذ يوم',
        'icon': 'local_offer',
      },
      {
        'title': 'تم إكمال الطلب بنجاح',
        'body': 'تم توصيل طلبك رقم #1023. شكراً لثقتك بنا!',
        'time': 'منذ يومين',
        'icon': 'check_circle',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الإشعارات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('لا توجد إشعارات حالياً', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getIcon(notif['icon']!), color: AppColors.primary),
                    ),
                    title: Text(
                      notif['title']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notif['body']!, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(notif['time']!, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'receipt':
        return Icons.receipt_long;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'local_offer':
        return Icons.local_offer;
      case 'check_circle':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }
}
