import '../../data/models/delivery_task_model.dart';

abstract class DeliveryTaskRepository {
  Future<List<DeliveryTaskModel>> getTaskPool();
  Future<DeliveryTaskModel> getTaskDetails(int taskId);
  Future<void> claimTask(int taskId, int driverId);
  Future<void> startTask(int taskId);
  Future<void> updateTaskProgress(int taskId, int currentStep);
  Future<void> completeTask(int taskId);
}
