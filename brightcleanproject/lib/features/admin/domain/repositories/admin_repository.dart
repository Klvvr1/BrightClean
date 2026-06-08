import '../../data/models/pending_user_model.dart';
import '../../data/models/admin_service_model.dart';

abstract class AdminRepository {
  Future<List<PendingUserModel>> getPendingApprovals();
  Future<void> approveUser(int userId);
  Future<List<dynamic>> getApprovedStaff();
  Future<List<dynamic>> getRecentOrders();
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
}
