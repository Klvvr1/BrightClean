import '../../data/models/pending_user_model.dart';

abstract class AdminRepository {
  Future<List<PendingUserModel>> getPendingApprovals();
  Future<void> approveUser(int userId);
}
