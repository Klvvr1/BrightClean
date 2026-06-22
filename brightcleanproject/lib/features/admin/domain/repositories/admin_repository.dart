import '../../data/models/pending_user_model.dart';
import '../../data/models/admin_service_model.dart';
import '../../data/models/activation_request_model.dart';
import '../../data/models/admin_summary_model.dart';
import '../../data/models/admin_offer_model.dart';
import '../../data/models/admin_audit_log_model.dart';

abstract class AdminRepository {
  Future<List<PendingUserModel>> getPendingApprovals();
  Future<void> approveUser(int userId);
  Future<void> rejectUser(int userId);
  Future<void> dismissUser(int userId);
  Future<void> warnUser(int userId, String reason);
  Future<List<dynamic>> getApprovedStaff();
  Future<AdminSummaryModel> getSummary();
  Future<List<dynamic>> getLiveOrders();
  Future<List<dynamic>> getRecentOrders();
  Future<List<AdminAuditLogModel>> getAuditLogs();
  Future<void> toggleSystemStatus(bool loginEnabled, String? message);
  Future<List<AdminServiceModel>> getServices();
  Future<void> createService(Map<String, dynamic> service);
  Future<void> updateService(int serviceId, Map<String, dynamic> service);
  Future<void> setServiceAvailability(int serviceId, bool isAvailable);
  Future<void> deleteService(int serviceId);
  Future<void> restoreService(int serviceId);
  Future<List<dynamic>> getLaundryAgentsWithServices();
  Future<List<int>> getAgentServiceIds(int agentId);
  Future<void> setAgentServices(int agentId, List<int> serviceIds);
  Future<List<ActivationRequestModel>> getServiceActivationRequests();
  Future<void> approveServiceActivationRequest(int agentId, int serviceId);
  Future<void> rejectServiceActivationRequest(int agentId, int serviceId);
  Future<void> sendNotification(Map<String, dynamic> notification);
  Future<List<dynamic>> getNotificationHistory();
  Future<List<AdminOfferModel>> getOffers();
  Future<void> createOffer(Map<String, dynamic> offer);
  Future<void> deleteOffer(int offerId);
}
