import '../../../../core/network/api_client.dart';
import '../../domain/repositories/admin_repository.dart';
import '../models/pending_user_model.dart';

class AdminRepositoryImpl implements AdminRepository {
  final BaseApiClient _apiClient;

  AdminRepositoryImpl({BaseApiClient? apiClient})
      : _apiClient = apiClient ?? BaseApiClient();

  @override
  Future<List<PendingUserModel>> getPendingApprovals() async {
    final response = await _apiClient.get('/api/admin/pending-approvals');
    if (response is List) {
      return response
          .map((json) => PendingUserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<void> approveUser(int userId) async {
    await _apiClient.post('/api/admin/approve/$userId');
  }
}
