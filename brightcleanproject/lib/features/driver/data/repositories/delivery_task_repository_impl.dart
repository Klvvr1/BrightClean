import '../../../../core/network/api_client.dart';
import '../../domain/repositories/delivery_task_repository.dart';
import '../models/delivery_task_model.dart';

class DeliveryTaskRepositoryImpl implements DeliveryTaskRepository {
  final BaseApiClient apiClient;

  DeliveryTaskRepositoryImpl({required this.apiClient});

  List<DeliveryTaskModel> _parseTaskList(dynamic response) {
    List<dynamic>? list;
    if (response is List) {
      list = response;
    } else if (response is Map<String, dynamic> &&
        response.containsKey('value')) {
      list = response['value'] as List<dynamic>;
    }
    if (list != null) {
      return list
          .map((item) =>
              DeliveryTaskModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<DeliveryTaskModel>> getTaskPool() async {
    try {
      final response = await apiClient.get('/api/deliverytasks/pool');
      return _parseTaskList(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<DeliveryTaskModel>> getMyTasks() async {
    try {
      final response = await apiClient.get('/api/deliverytasks/my');
      return _parseTaskList(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> getAvailability() async {
    try {
      final response = await apiClient.get('/api/deliverytasks/availability');
      if (response is Map<String, dynamic>) {
        return response['isAvailable'] == true ||
            response['IsAvailable'] == true;
      }
      if (response is Map) {
        return response['isAvailable'] == true ||
            response['IsAvailable'] == true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> setAvailability(bool isAvailable) async {
    try {
      final response = await apiClient.patch(
        '/api/deliverytasks/availability',
        body: {'isAvailable': isAvailable},
      );
      if (response is Map<String, dynamic>) {
        return response['isAvailable'] == true ||
            response['IsAvailable'] == true;
      }
      if (response is Map) {
        return response['isAvailable'] == true ||
            response['IsAvailable'] == true;
      }
      return isAvailable;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<DeliveryTaskModel> getTaskDetails(int taskId) async {
    try {
      final response = await apiClient.get('/api/deliverytasks/$taskId');
      if (response is Map<String, dynamic>) {
        return DeliveryTaskModel.fromJson(response);
      }
      if (response is Map) {
        return DeliveryTaskModel.fromJson(
          response.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
      throw Exception('Invalid delivery task response');
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
  Future<void> startTask(int taskId) async {
    try {
      await apiClient.post('/api/deliverytasks/$taskId/start');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateTaskProgress(int taskId, int currentStep) async {
    try {
      await apiClient.patch(
        '/api/deliverytasks/$taskId/progress',
        body: {'currentStep': currentStep},
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
