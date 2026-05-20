import '../../../../core/network/api_client.dart';
import '../../domain/repositories/delivery_task_repository.dart';
import '../models/delivery_task_model.dart';

class DeliveryTaskRepositoryImpl implements DeliveryTaskRepository {
  final BaseApiClient apiClient;

  DeliveryTaskRepositoryImpl({required this.apiClient});

  @override
  Future<List<DeliveryTaskModel>> getTaskPool() async {
    try {
      final response = await apiClient.get('/api/deliverytasks/pool');
      List<dynamic>? list;
      if (response is List) {
        list = response;
      } else if (response is Map<String, dynamic> && response.containsKey('value')) {
        list = response['value'] as List<dynamic>;
      }
      if (list != null) {
        return list
            .map((item) => DeliveryTaskModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> claimTask(int taskId, int driverId) async {
    try {
      await apiClient.post(
        '/api/deliverytasks/$taskId/claim',
        body: {'deliveryStaffID': driverId},
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> completeTask(int taskId) async {
    try {
      await apiClient.post('/api/deliverytasks/$taskId/complete');
    } catch (e) {
      rethrow;
    }
  }
}
