import '../../../../core/network/api_client.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/login_response_model.dart';
import '../models/register_agent_model.dart';
import '../models/register_client_model.dart';
import 'package:http/http.dart' as http;

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
  Future<void> registerAgent(
    RegisterAgentModel agentModel, {
    required String commercialRegisterImagePath,
    required String nationalIdImagePath,
  }) async {
    final fields = agentModel.toJson().map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        );

    await _apiClient.postMultipart(
      '/api/auth/register/agent',
      fields: fields,
      files: [
        await http.MultipartFile.fromPath(
          'commercialRegisterImage',
          commercialRegisterImagePath,
        ),
        await http.MultipartFile.fromPath(
          'nationalIdImage',
          nationalIdImagePath,
        ),
      ],
    );
  }

  @override
  Future<void> registerClient(RegisterClientModel clientModel) async {
    await _apiClient.post(
      '/api/auth/register/client',
      body: clientModel.toJson(),
    );
  }

  @override
  Future<String> forgotPassword(String email) async {
    final response = await _apiClient.post(
      '/api/auth/forgot-password',
      body: {'email': email},
    );
    if (response is Map<String, dynamic>) {
      return response['otp']?.toString() ?? '';
    }
    return '';
  }

  @override
  Future<void> resetPassword(String email, String token, String newPassword) async {
    await _apiClient.post(
      '/api/auth/reset-password',
      body: {
        'email': email,
        'token': token,
        'newPassword': newPassword,
      },
    );
  }

  @override
  Future<void> updateProfile(String firstName, String lastName, String phone) async {
    await _apiClient.put(
      '/api/users/profile',
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNo': phone,
      },
    );
  }
}
