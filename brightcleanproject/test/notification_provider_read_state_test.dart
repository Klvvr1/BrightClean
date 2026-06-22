import 'package:brightcleanproject/core/network/api_client.dart';
import 'package:brightcleanproject/features/customer/data/providers/notification_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NotificationApiClient extends BaseApiClient {
  final List<Map<String, dynamic>> response;

  _NotificationApiClient(this.response);

  @override
  Future<dynamic> get(String endpoint) async => response;
}

void main() {
  test('NotificationProvider persists read notifications locally', () async {
    SharedPreferences.setMockInitialValues({});
    final response = [
      {
        'notificationID': 5,
        'userID': 77,
        'title': 'تنبيه',
        'message': 'رسالة اختبار',
        'date': DateTime(2026, 6, 22).toIso8601String(),
      },
      {
        'notificationID': 6,
        'userID': 77,
        'title': 'طلب',
        'message': 'رسالة طلب',
        'date': DateTime(2026, 6, 22).toIso8601String(),
      },
    ];

    final firstProvider = NotificationProvider(
      apiClient: _NotificationApiClient(response),
    );
    await firstProvider.fetchNotifications();

    expect(firstProvider.unreadCount, 2);

    await firstProvider.markAllAsRead();

    final secondProvider = NotificationProvider(
      apiClient: _NotificationApiClient(response),
    );
    await secondProvider.fetchNotifications();

    expect(secondProvider.unreadCount, 0);
    expect(secondProvider.notifications.every((n) => n.isRead), isTrue);
  });
}
