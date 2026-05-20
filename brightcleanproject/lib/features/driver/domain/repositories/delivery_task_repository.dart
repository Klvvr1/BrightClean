import '../../data/models/delivery_task_model.dart';

abstract class DeliveryTaskRepository {
  Future<List<DeliveryTaskModel>> getTaskPool();
  Future<void> claimTask(int taskId, int driverId);
  Future<void> completeTask(int taskId);
}
