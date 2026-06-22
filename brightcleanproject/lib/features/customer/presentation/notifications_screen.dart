import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/controllers/language_controller.dart';
import '../data/providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<NotificationProvider>();
      try {
        await provider.fetchNotifications();
        if (provider.errorMessage == null) {
          provider.markAllAsRead();
        }
      } catch (e) {
        // Error already handled by provider
      }
    });
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    final isArabic = LanguageController().isArabic;

    if (difference.inMinutes < 1) {
      return isArabic ? 'الآن' : 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return isArabic ? 'منذ $mins دقيقة' : '$mins mins ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return isArabic ? 'منذ $hours ساعة' : '$hours hours ago';
    } else {
      final days = difference.inDays;
      return isArabic ? 'منذ $days يوم' : '$days days ago';
    }
  }

  IconData _getIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('طلب') || lowerTitle.contains('order') || lowerTitle.contains('استلام') || lowerTitle.contains('receipt')) {
      return Icons.receipt_long;
    } else if (lowerTitle.contains('سائق') || lowerTitle.contains('driver') || lowerTitle.contains('توصيل') || lowerTitle.contains('shipping')) {
      return Icons.local_shipping;
    } else if (lowerTitle.contains('عرض') || lowerTitle.contains('خصم') || lowerTitle.contains('كوبون') || lowerTitle.contains('offer') || lowerTitle.contains('coupon')) {
      return Icons.local_offer;
    } else if (lowerTitle.contains('تم') || lowerTitle.contains('إكمال') || lowerTitle.contains('نجاح') || lowerTitle.contains('success') || lowerTitle.contains('complete')) {
      return Icons.check_circle;
    }
    return Icons.notifications;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = LanguageController().isArabic;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          isArabic ? 'الإشعارات' : 'Notifications',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      isArabic
                          ? 'حدث خطأ أثناء تحميل الإشعارات'
                          : 'Error loading notifications',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: () => provider.fetchNotifications(),
                      child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final notifications = provider.notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    isArabic ? 'لا توجد إشعارات حالياً' : 'No notifications at the moment',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
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
                    child: Icon(_getIcon(notif.title), color: theme.colorScheme.primary),
                  ),
                  title: Text(
                    notif.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        notif.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _getTimeAgo(notif.date),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
