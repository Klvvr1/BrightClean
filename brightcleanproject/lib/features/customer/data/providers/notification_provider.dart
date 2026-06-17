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
      }
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
