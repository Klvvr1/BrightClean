import '../../../../core/network/api_client.dart';
import '../../../customer/data/models/booking_model.dart';

class AgentBookingRepository {
  final BaseApiClient apiClient;

  AgentBookingRepository({BaseApiClient? apiClient})
      : apiClient = apiClient ?? BaseApiClient();

  Future<List<Map<String, dynamic>>> getMyBookings() async {
    final response = await apiClient.get('/api/bookings/agent/my');
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList();
    }
    if (response is Map<String, dynamic> && response['value'] is List) {
      return (response['value'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<void> acceptBooking(int bookingId) async {
    await apiClient.post('/api/bookings/$bookingId/accept');
  }

  Future<void> rejectBooking(int bookingId, String reason) async {
    await apiClient.post(
      '/api/bookings/$bookingId/reject',
      body: {'reason': reason},
    );
  }

  Future<void> startBooking(int bookingId) async {
    await apiClient.post('/api/bookings/$bookingId/start');
  }

  Future<void> markReady(int bookingId) async {
    await apiClient.post('/api/bookings/$bookingId/ready');
  }

  Future<bool> toggleStoreStatus() async {
    final response = await apiClient.post('/api/bookings/toggle-store-status');
    if (response is Map<String, dynamic>) {
      return !(response['isStoreClosed'] as bool? ?? true);
    }
    return false;
  }

  Future<List<ServiceCatalogItemModel>> getMyServices(int agentId) async {
    final response = await apiClient.get('/api/services/agents/$agentId');
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(ServiceCatalogItemModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>?> getMyProfile() async {
    final response = await apiClient.get('/api/users/me');
    if (response is Map<String, dynamic>) {
      return response;
    }
    return null;
  }
}
