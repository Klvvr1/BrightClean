import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/delivery_task_repository.dart';
import '../repositories/delivery_task_repository_impl.dart';
import '../models/delivery_task_model.dart';

class DriverProvider extends ChangeNotifier {
  final DeliveryTaskRepository deliveryTaskRepository;

  List<DeliveryTaskModel> _tasks = [];
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;

  List<DeliveryTaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;

  DriverProvider({DeliveryTaskRepository? deliveryTaskRepository})
      : deliveryTaskRepository = deliveryTaskRepository ??
            DeliveryTaskRepositoryImpl(apiClient: BaseApiClient());

  Future<void> fetchTaskPool() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await deliveryTaskRepository.getTaskPool();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> claimTask(int taskId, int driverId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await deliveryTaskRepository.claimTask(taskId, driverId);
      await fetchTaskPool();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeTask(int taskId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await deliveryTaskRepository.completeTask(taskId);
      await fetchTaskPool();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }
}
