import 'package:flutter/foundation.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/user_error_message.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../models/pending_user_model.dart';
import '../models/admin_service_model.dart';
import '../models/activation_request_model.dart';
import '../models/admin_summary_model.dart';
import '../models/admin_offer_model.dart';
import '../models/admin_audit_log_model.dart';

class AdminProvider with ChangeNotifier {
  final AdminRepository adminRepository;

  List<PendingUserModel> _pendingUsers = [];
  List<dynamic> _approvedStaff = [];
  List<dynamic> _recentOrders = [];
  List<dynamic> _laundryAgentsWithServices = [];
  List<AdminServiceModel> _services = [];
  List<ActivationRequestModel> _serviceActivationRequests = [];
  List<AdminOfferModel> _offers = [];
  List<AdminAuditLogModel> _auditLogs = [];
  List<dynamic> _notificationHistory = [];
  AdminSummaryModel _summary = AdminSummaryModel.empty();
  bool _isLoading = false;
  bool _isAuditLogsLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;
  String? _refreshErrorMessage;

  AdminProvider({AdminRepository? adminRepository})
      : adminRepository = adminRepository ?? AdminRepositoryImpl();

  List<PendingUserModel> get pendingUsers => _pendingUsers;
  List<dynamic> get approvedStaff => _approvedStaff;
  List<dynamic> get recentOrders => _recentOrders;
  List<dynamic> get laundryAgentsWithServices => _laundryAgentsWithServices;
  List<AdminServiceModel> get services => _services;
  List<ActivationRequestModel> get serviceActivationRequests =>
      _serviceActivationRequests;
  List<AdminOfferModel> get offers => _offers;
  List<AdminAuditLogModel> get auditLogs => _auditLogs;
  List<dynamic> get notificationHistory => _notificationHistory;
  AdminSummaryModel get summary => _summary;
  bool get isLoading => _isLoading;
  bool get isAuditLogsLoading => _isAuditLogsLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;
  String? get refreshErrorMessage => _refreshErrorMessage;

  Future<void> fetchApprovedStaff() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _approvedStaff = await adminRepository.getApprovedStaff();
    } on ServerException catch (e) {
      _errorMessage = userMessageFromError(e,
          fallback: 'حدث خطأ أثناء تحميل الموظفين المعتمدين');
    } catch (e) {
      _errorMessage = userMessageFromError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSummary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await adminRepository.getSummary();
    } on ServerException catch (e) {
      _errorMessage = userMessageFromError(e,
          fallback: 'حدث خطأ أثناء تحميل ملخص لوحة المشرف');
    } catch (e) {
      _errorMessage = userMessageFromError(e);
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
      _errorMessage = userMessageFromError(e,
          fallback: 'حدث خطأ أثناء تحميل الطلبات الأخيرة');
    } catch (e) {
      _errorMessage = userMessageFromError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAuditLogs() async {
    _isAuditLogsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _auditLogs = await adminRepository.getAuditLogs();
    } on ServerException catch (e) {
      _errorMessage = userMessageFromError(e,
          fallback: 'حدث خطأ أثناء تحميل سجل عمليات المشرف');
    } catch (e) {
      _errorMessage = userMessageFromError(e);
    } finally {
      _isAuditLogsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOffers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _offers = await adminRepository.getOffers();
    } on ServerException catch (e) {
      _errorMessage =
          userMessageFromError(e, fallback: 'حدث خطأ أثناء تحميل العروض');
    } catch (e) {
      _errorMessage = userMessageFromError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNotificationHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notificationHistory = await adminRepository.getNotificationHistory();
    } on ServerException catch (e) {
      _errorMessage = userMessageFromError(e,
          fallback: 'حدث خطأ أثناء تحميل سجل الإشعارات');
    } catch (e) {
      _errorMessage = userMessageFromError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendNotification(Map<String, dynamic> notification) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await adminRepository.sendNotification(notification);
      _notificationHistory = await adminRepository.getNotificationHistory();
    } on ServerException catch (e) {
      _errorMessage =
          userMessageFromError(e, fallback: 'حدث خطأ أثناء إرسال الإشعار');
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> createOffer(Map<String, dynamic> offer) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await adminRepository.createOffer(offer);
      _offers = await adminRepository.getOffers();
      _notificationHistory = await adminRepository.getNotificationHistory();
    } on ServerException catch (e) {
      _errorMessage =
          userMessageFromError(e, fallback: 'حدث خطأ أثناء إنشاء العرض');
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteOffer(int offerId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await adminRepository.deleteOffer(offerId);
      _offers = await adminRepository.getOffers();
    } on ServerException catch (e) {
      _errorMessage =
          userMessageFromError(e, fallback: 'حدث خطأ أثناء حذف العرض');
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isActionLoading = false;
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
      _errorMessage = userMessageFromError(e,
          fallback: 'حدث خطأ أثناء تحميل الطلبات المعلقة');
    } catch (e) {
      _errorMessage = userMessageFromError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveUser(int userId) async {
    _isActionLoading = true;
    _errorMessage = null;
    _refreshErrorMessage = null;
    notifyListeners();

    try {
      await adminRepository.approveUser(userId);
    } on ServerException catch (e) {
      _errorMessage = userMessageFromError(e,
          fallback: 'حدث خطأ أثناء الموافقة على المستخدم');
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    }

    try {
      await fetchPendingUsers();
      await fetchApprovedStaff();
      await fetchAuditLogs();
    } catch (e) {
      debugPrint('Error refreshing admin data after approval: $e');
      _refreshErrorMessage = userMessageFromError(e,
          fallback: 'حدث خطأ أثناء تحديث البيانات بعد الموافقة');
      notifyListeners();
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> rejectUser(int userId) async {
    _isActionLoading = true;
    _errorMessage = null;
    _refreshErrorMessage = null;
    notifyListeners();

    try {
      await adminRepository.rejectUser(userId);
    } on ServerException catch (e) {
      _errorMessage = userMessageFromError(e,
          fallback: 'حدث خطأ أثناء رفض المستخدم');
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    }

    try {
      await fetchPendingUsers();
      await fetchAuditLogs();
    } catch (e) {
      debugPrint('Error refreshing admin data after rejection: $e');
      _refreshErrorMessage = userMessageFromError(e,
          fallback: 'حدث خطأ أثناء تحديث البيانات بعد الرفض');
      notifyListeners();
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
      _errorMessage = userMessageFromError(e,
          fallback: 'حدث خطأ أثناء تغيير حالة الصيانة');
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = userMessageFromError(e);
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
      _errorMessage =
          userMessageFromError(e, fallback: 'حدث خطأ أثناء تحميل الخدمات');
    } catch (e) {
      _errorMessage = userMessageFromError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchServiceActivationRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _serviceActivationRequests =
          await adminRepository.getServiceActivationRequests();
    } on ServerException catch (e) {
      _errorMessage = userMessageFromError(e,
          fallback: 'حدث خطأ أثناء تحميل طلبات تعديل الخدمات');
    } catch (e) {
      _errorMessage = userMessageFromError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveServiceActivationRequest(
      int agentId, int serviceId) async {
    await _runServiceActivationAction(
      () => adminRepository.approveServiceActivationRequest(agentId, serviceId),
    );
  }

  Future<void> rejectServiceActivationRequest(
      int agentId, int serviceId) async {
    await _runServiceActivationAction(
      () => adminRepository.rejectServiceActivationRequest(agentId, serviceId),
    );
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
      _errorMessage =
          userMessageFromError(e, fallback: 'حدث خطأ أثناء تنفيذ العملية');
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> _runServiceActivationAction(
      Future<void> Function() action) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      _serviceActivationRequests =
          await adminRepository.getServiceActivationRequests();
      _services = await adminRepository.getServices();
      try {
        _laundryAgentsWithServices =
            await adminRepository.getLaundryAgentsWithServices();
      } catch (e) {
        debugPrint('Error refreshing laundry agents after service request: $e');
      }
    } on ServerException catch (e) {
      _errorMessage = userMessageFromError(e,
          fallback: 'حدث خطأ أثناء تنفيذ طلب تعديل الخدمة');
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }
}
