import '../../data/models/login_response_model.dart';
import '../../data/models/register_agent_model.dart';
import '../../data/models/register_client_model.dart';

abstract class AuthRepository {
  Future<LoginResponseModel> login(String email, String password);
  Future<void> registerAgent(
    RegisterAgentModel agentModel, {
    required String commercialRegisterImagePath,
    required String nationalIdImagePath,
  });
  Future<void> registerClient(RegisterClientModel clientModel);
  Future<String> forgotPassword(String email);
  Future<void> resetPassword(String email, String token, String newPassword);
  Future<void> updateProfile(String firstName, String lastName, String phone);
}
