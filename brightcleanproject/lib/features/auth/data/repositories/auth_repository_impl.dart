import '../../../../core/network/api_client.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/login_response_model.dart';
import '../models/register_agent_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final BaseApiClient _apiClient;

  AuthRepositoryImpl({BaseApiClient? apiClient})
      : _apiClient = apiClient ?? BaseApiClient();

  @override
  Future<LoginResponseModel> login(String email, String password) async {
    final response = await _apiClient.post(
      '/api/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );
    return LoginResponseModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> registerAgent(RegisterAgentModel agentModel) async {
    await _apiClient.post(
      '/api/auth/register/agent',
      body: agentModel.toJson(),
    );
  }
}
