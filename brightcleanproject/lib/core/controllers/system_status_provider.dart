import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../network/api_client.dart';

class SystemStatusProvider with ChangeNotifier {
  bool _isLoginEnabled = true;
  String? _maintenanceMessage;
  bool _isLoading = false;

  bool get isLoginEnabled => _isLoginEnabled;
  String? get maintenanceMessage => _maintenanceMessage;
  bool get isLoading => _isLoading;

  Future<void> checkStatus() async {
    _isLoading = true;
    // Don't notify listeners here to avoid unnecessary rebuilds during startup
    
    try {
      final response = await http.get(Uri.parse('${BaseApiClient.defaultBaseUrl}/systemstatus/status'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _isLoginEnabled = data['loginEnabled'] ?? true;
        _maintenanceMessage = data['message'];
      } else {
        // Fallback to true if API fails
        _isLoginEnabled = true;
      }
    } catch (e) {
      debugPrint('Error fetching system status: $e');
      // Fallback
      _isLoginEnabled = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
