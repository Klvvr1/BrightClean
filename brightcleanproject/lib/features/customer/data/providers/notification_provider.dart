import 'package:flutter/foundation.dart';
import '../../../../core/error/user_error_message.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/app_notification.dart';

class NotificationProvider with ChangeNotifier {
  final BaseApiClient apiClient;
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  NotificationProvider({BaseApiClient? apiClient})
      : apiClient = apiClient ?? BaseApiClient();

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.get('api/notifications');
      if (response is List) {
        _notifications = response
            .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('🔔 NotificationProvider: fetched ${_notifications.length} notifications, unread: $unreadCount');
      }
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    if (unreadCount == 0) return;
    _notifications = _notifications
        .map((n) => n.isRead ? n : AppNotification(
              notificationID: n.notificationID,
              userID: n.userID,
              title: n.title,
              message: n.message,
              date: n.date,
              isRead: true,
            ))
        .toList();
    debugPrint('🔔 NotificationProvider: marked all as read');
    notifyListeners();
  }
}
