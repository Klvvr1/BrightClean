import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_styles.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('الإشعارات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: AppSpacing.md),
                  Text('لا توجد إشعارات حالياً', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Container(
                  decoration: AppStyles.surface(context),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getIcon(notif['icon']!), color: theme.colorScheme.primary),
                    ),
                    title: Text(
                      notif['title']!,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xs),
                        Text(notif['body']!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                        const SizedBox(height: AppSpacing.sm),
                        Text(notif['time']!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
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
