import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/user_error_message.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/app_notification.dart';

class NotificationProvider with ChangeNotifier {
  static const String _readNotificationIdsKey = 'read_notification_ids';

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
        final readNotificationIds = await _loadReadNotificationIds();
        _notifications = response
            .map((json) =>
                AppNotification.fromJson(json as Map<String, dynamic>))
            .map((notification) => _withReadState(
                  notification,
                  notification.isRead ||
                      readNotificationIds.contains(
                        _readNotificationKey(notification),
                      ),
                ))
            .toList();
        debugPrint(
            '🔔 NotificationProvider: fetched ${_notifications.length} notifications, unread: $unreadCount');
      }
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    if (unreadCount == 0) return;
    final readNotificationIds = await _loadReadNotificationIds();
    for (final notification in _notifications) {
      if (notification.notificationID > 0) {
        readNotificationIds.add(_readNotificationKey(notification));
      }
    }
    await _saveReadNotificationIds(readNotificationIds);
    _notifications = _notifications
        .map((n) => n.isRead
            ? n
            : AppNotification(
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

  String _readNotificationKey(AppNotification notification) {
    return '${notification.userID}:${notification.notificationID}';
  }

  AppNotification _withReadState(AppNotification notification, bool isRead) {
    return AppNotification(
      notificationID: notification.notificationID,
      userID: notification.userID,
      title: notification.title,
      message: notification.message,
      date: notification.date,
      isRead: isRead,
    );
  }

  Future<Set<String>> _loadReadNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_readNotificationIdsKey) ?? <String>[]).toSet();
  }

  Future<void> _saveReadNotificationIds(Set<String> readNotificationIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _readNotificationIdsKey,
      readNotificationIds.toList(),
    );
  }
}
