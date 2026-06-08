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
  bool _isAvailable = false;
  String? _errorMessage;

  List<DeliveryTaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  bool get isAvailable => _isAvailable;
  String? get errorMessage => _errorMessage;

  DriverProvider({DeliveryTaskRepository? deliveryTaskRepository})
      : deliveryTaskRepository = deliveryTaskRepository ??
            DeliveryTaskRepositoryImpl(apiClient: BaseApiClient());

  Future<void> fetchTaskPool() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final poolTasks = await deliveryTaskRepository.getTaskPool();
      final myTasks = await deliveryTaskRepository.getMyTasks();
      final merged = <int, DeliveryTaskModel>{};
      for (final task in poolTasks) {
        merged[task.taskID] = task;
      }
      for (final task in myTasks) {
        merged[task.taskID] = task;
      }
      _tasks = merged.values.toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAvailability() async {
    try {
      _isAvailable = await deliveryTaskRepository.getAvailability();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> setAvailability(bool isAvailable) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isAvailable = await deliveryTaskRepository.setAvailability(isAvailable);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<DeliveryTaskModel> fetchTaskDetails(int taskId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final task = await deliveryTaskRepository.getTaskDetails(taskId);
      final index = _tasks.indexWhere((item) => item.taskID == task.taskID);
      if (index >= 0) {
        _tasks[index] = task;
      } else {
        _tasks.add(task);
      }
      return task;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isActionLoading = false;
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

  Future<void> startTask(int taskId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await deliveryTaskRepository.startTask(taskId);
      await fetchTaskPool();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTaskProgress(int taskId, int currentStep) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await deliveryTaskRepository.updateTaskProgress(taskId, currentStep);
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
