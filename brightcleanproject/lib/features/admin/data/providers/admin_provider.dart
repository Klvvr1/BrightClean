import 'package:flutter/foundation.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../models/pending_user_model.dart';
import '../models/admin_service_model.dart';

class AdminProvider with ChangeNotifier {
  final AdminRepository adminRepository;

  List<PendingUserModel> _pendingUsers = [];
  List<dynamic> _approvedStaff = [];
  List<dynamic> _recentOrders = [];
  List<dynamic> _laundryAgentsWithServices = [];
  List<AdminServiceModel> _services = [];
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;

  AdminProvider({AdminRepository? adminRepository})
      : adminRepository = adminRepository ?? AdminRepositoryImpl();

  List<PendingUserModel> get pendingUsers => _pendingUsers;
  List<dynamic> get approvedStaff => _approvedStaff;
  List<dynamic> get recentOrders => _recentOrders;
  List<dynamic> get laundryAgentsWithServices => _laundryAgentsWithServices;
  List<AdminServiceModel> get services => _services;
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchApprovedStaff() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _approvedStaff = await adminRepository.getApprovedStaff();
    } on ServerException catch (e) {
      _errorMessage = e.message ?? 'حدث خطأ أثناء تحميل الموظفين المعتمدين';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRecentOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recentOrders = await adminRepository.getRecentOrders();
    } on ServerException catch (e) {
      _errorMessage = e.message ??
          'Ø­Ø¯Ø« Ø®Ø·Ø£ Ø£Ø«Ù†Ø§Ø¡ ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø·Ù„Ø¨Ø§Øª Ø§Ù„Ø£Ø®ÙŠØ±Ø©';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPendingUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pendingUsers = await adminRepository.getPendingApprovals();
    } on ServerException catch (e) {
      _errorMessage = e.message ?? 'حدث خطأ أثناء تحميل الطلبات المعلقة';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveUser(int userId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await adminRepository.approveUser(userId);
    } on ServerException catch (e) {
      _errorMessage = e.message ?? 'حدث خطأ أثناء الموافقة على المستخدم';
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    }

    try {
      await fetchPendingUsers();
    } catch (e) {
      debugPrint('Error refreshing pending users after approval: $e');
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleSystemStatus(bool loginEnabled, String? message) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await adminRepository.toggleSystemStatus(loginEnabled, message);
    } on ServerException catch (e) {
      _errorMessage = e.message ?? 'حدث خطأ أثناء تغيير حالة الصيانة';
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchServices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _services = await adminRepository.getServices();
      try {
        _laundryAgentsWithServices =
            await adminRepository.getLaundryAgentsWithServices();
      } catch (e) {
        debugPrint('Error refreshing laundry agents with services: $e');
      }
    } on ServerException catch (e) {
      _errorMessage = e.message ?? 'حدث خطأ أثناء تحميل الخدمات';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createService(Map<String, dynamic> service) async {
    await _runServiceAction(() => adminRepository.createService(service));
  }

  Future<void> updateService(
      int serviceId, Map<String, dynamic> service) async {
    await _runServiceAction(
        () => adminRepository.updateService(serviceId, service));
  }

  Future<void> setServiceAvailability(int serviceId, bool isAvailable) async {
    await _runServiceAction(
      () => adminRepository.setServiceAvailability(serviceId, isAvailable),
    );
  }

  Future<void> deleteService(int serviceId) async {
    await _runServiceAction(() => adminRepository.deleteService(serviceId));
  }

  Future<void> restoreService(int serviceId) async {
    await _runServiceAction(() => adminRepository.restoreService(serviceId));
  }

  Future<List<int>> getAgentServiceIds(int agentId) async {
    return adminRepository.getAgentServiceIds(agentId);
  }

  Future<void> setAgentServices(int agentId, List<int> serviceIds) async {
    await _runServiceAction(
        () => adminRepository.setAgentServices(agentId, serviceIds));
  }

  Future<void> _runServiceAction(Future<void> Function() action) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      _services = await adminRepository.getServices();
      try {
        _laundryAgentsWithServices =
            await adminRepository.getLaundryAgentsWithServices();
      } catch (e) {
        debugPrint('Error refreshing laundry agents with services: $e');
      }
      try {
        _approvedStaff = await adminRepository.getApprovedStaff();
      } catch (e) {
        debugPrint('Error refreshing approved staff after service action: $e');
      }
    } on ServerException catch (e) {
      _errorMessage = e.message ?? 'حدث خطأ أثناء تنفيذ العملية';
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }
}
