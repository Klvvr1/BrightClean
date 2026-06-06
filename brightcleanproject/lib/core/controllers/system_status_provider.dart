import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../network/api_client.dart';
import '../error/exceptions.dart';

class SystemStatusProvider with ChangeNotifier {
  bool _isLoginEnabled = true;
  String? _maintenanceMessage;
  bool _isLoading = false;
  final BaseApiClient _apiClient = BaseApiClient();

  bool get isLoginEnabled => _isLoginEnabled;
  String? get maintenanceMessage => _maintenanceMessage;
  bool get isLoading => _isLoading;

  Future<void> checkStatus() async {
    _isLoading = true;
    // Don't notify listeners here to avoid unnecessary rebuilds during startup

    try {
      final data = await _apiClient.get('/systemstatus/status');

      if (data != null) {
        _isLoginEnabled = data['loginEnabled'] ?? false;
        _maintenanceMessage = data['message'] ?? 'النظام تحت الصيانة';
      } else {
        // Fail-closed: if response is null, disable login
        _isLoginEnabled = false;
        _maintenanceMessage = 'النظام تحت الصيانة';
      }
    } on ServerException catch (e) {
      debugPrint('Error fetching system status: ${e.message}');
      // Fail-closed on server error
      _isLoginEnabled = false;
      _maintenanceMessage = 'النظام تحت الصيانة';
    } catch (e) {
      debugPrint('Error fetching system status: $e');
      // Fail-closed on any error
      _isLoginEnabled = false;
      _maintenanceMessage = 'النظام تحت الصيانة';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
