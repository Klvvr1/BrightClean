import '../../../../core/network/api_client.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/repositories/admin_repository.dart';
import '../models/pending_user_model.dart';
import '../models/admin_service_model.dart';
import '../models/activation_request_model.dart';
import '../models/admin_summary_model.dart';
import '../models/admin_offer_model.dart';

class AdminRepositoryImpl implements AdminRepository {
  final BaseApiClient _apiClient;

  AdminRepositoryImpl({BaseApiClient? apiClient})
      : _apiClient = apiClient ?? BaseApiClient();

  @override
  Future<List<PendingUserModel>> getPendingApprovals() async {
    final response = await _apiClient.get('/api/admin/pending-approvals');
    if (response is List) {
      return response
          .map(
              (json) => PendingUserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw ServerException(
        message: 'Invalid API response format for pending approvals');
  }

  @override
  Future<void> approveUser(int userId) async {
    await _apiClient.post('/api/admin/approve/$userId');
  }

  @override
  Future<List<dynamic>> getApprovedStaff() async {
    final response = await _apiClient.get('/api/admin/staff');
    if (response is List) {
      return response;
    }
    throw ServerException(
        message: 'Invalid API response format for approved staff');
  }

  @override
  Future<AdminSummaryModel> getSummary() async {
    final response = await _apiClient.get('/api/admin/summary');
    if (response is Map<String, dynamic>) {
      return AdminSummaryModel.fromJson(response);
    }
    throw ServerException(
        message: 'Invalid API response format for admin summary');
  }

  @override
  Future<List<dynamic>> getRecentOrders() async {
    final response = await _apiClient.get('/api/admin/recent-orders');
    if (response is List) {
      return response;
    }
    throw ServerException(
        message: 'Invalid API response format for recent orders');
  }

  @override
  Future<void> toggleSystemStatus(bool loginEnabled, String? message) async {
    await _apiClient.post(
      '/api/systemstatus/toggle',
      body: {
        'loginEnabled': loginEnabled,
        'message': message,
      },
    );
  }

  @override
  Future<List<AdminServiceModel>> getServices() async {
    final response = await _apiClient.get('/api/admin/services');
    if (response is List) {
      return response
          .map((json) =>
              AdminServiceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw ServerException(message: 'Invalid API response format for services');
  }

  @override
  Future<void> createService(Map<String, dynamic> service) async {
    await _apiClient.post('/api/admin/services', body: service);
  }

  @override
  Future<void> updateService(
      int serviceId, Map<String, dynamic> service) async {
    await _apiClient.put('/api/admin/services/$serviceId', body: service);
  }

  @override
  Future<void> setServiceAvailability(int serviceId, bool isAvailable) async {
    await _apiClient.patch(
      '/api/admin/services/$serviceId/availability',
      body: {'isAvailable': isAvailable},
    );
  }

  @override
  Future<void> deleteService(int serviceId) async {
    await _apiClient.delete('/api/admin/services/$serviceId');
  }

  @override
  Future<void> restoreService(int serviceId) async {
    await _apiClient.patch('/api/admin/services/$serviceId/restore');
  }

  @override
  Future<List<dynamic>> getLaundryAgentsWithServices() async {
    final response = await _apiClient.get('/api/users/agents');
    if (response is List) {
      return response;
    }
    throw ServerException(
        message: 'Invalid API response format for laundry agents');
  }

  @override
  Future<List<int>> getAgentServiceIds(int agentId) async {
    final response = await _apiClient.get('/api/users/agents/$agentId');
    if (response is Map<String, dynamic>) {
      final rawServiceIds = response['serviceIds'] ?? response['serviceIDs'];
      if (rawServiceIds is List) {
        return rawServiceIds
            .map((id) => id is int ? id : int.tryParse(id.toString()))
            .whereType<int>()
            .toList();
      }
      final rawServices = response['services'];
      if (rawServices is List) {
        return rawServices
            .whereType<Map>()
            .map((service) =>
                service['serviceID'] ??
                service['serviceId'] ??
                service['ServiceID'])
            .map((id) => id is int ? id : int.tryParse(id.toString()))
            .whereType<int>()
            .toList();
      }
    }
    throw ServerException(
        message: 'Invalid API response format for agent services');
  }

  @override
  Future<void> setAgentServices(int agentId, List<int> serviceIds) async {
    await _apiClient.post(
      '/api/admin/agents/$agentId/services',
      body: {'serviceIDs': serviceIds},
    );
  }

  @override
  Future<List<ActivationRequestModel>> getServiceActivationRequests() async {
    final response =
        await _apiClient.get('/api/admin/service-activation-requests');
    if (response is List) {
      final result = <ActivationRequestModel>[];
      for (int i = 0; i < response.length; i++) {
        final item = response[i];
        if (item is! Map) {
          throw FormatException(
            'Invalid item at index $i in service activation requests: expected Map but got ${item.runtimeType}. Value: $item',
          );
        }
        result.add(ActivationRequestModel.fromJson(
          item.map((key, value) => MapEntry(key.toString(), value)),
        ));
      }
      return result;
    }
    throw ServerException(
        message: 'Invalid API response format for service activation requests');
  }

  @override
  Future<void> approveServiceActivationRequest(
      int agentId, int serviceId) async {
    await _apiClient
        .post('/api/admin/agents/$agentId/services/$serviceId/approve');
  }

  @override
  Future<void> rejectServiceActivationRequest(
      int agentId, int serviceId) async {
    await _apiClient
        .post('/api/admin/agents/$agentId/services/$serviceId/reject');
  }

  @override
  Future<void> sendNotification(Map<String, dynamic> notification) async {
    await _apiClient.post('/api/admin/notifications', body: notification);
  }

  @override
  Future<List<dynamic>> getNotificationHistory() async {
    final response = await _apiClient.get('/api/admin/notifications');
    if (response is List) {
      return response;
    }
    throw ServerException(
        message: 'Invalid API response format for notification history');
  }

  @override
  Future<List<AdminOfferModel>> getOffers() async {
    final response = await _apiClient.get('/api/admin/offers');
    if (response is List) {
      return response
          .map((json) =>
              AdminOfferModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw ServerException(message: 'Invalid API response format for offers');
  }

  @override
  Future<void> createOffer(Map<String, dynamic> offer) async {
    await _apiClient.post('/api/admin/offers', body: offer);
  }

  @override
  Future<void> deleteOffer(int offerId) async {
    await _apiClient.delete('/api/admin/offers/$offerId');
  }
}
