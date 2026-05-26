import '../../data/models/login_response_model.dart';
import '../../data/models/register_agent_model.dart';
import '../../data/models/register_client_model.dart';

abstract class AuthRepository {
  Future<LoginResponseModel> login(String email, String password);
  Future<void> registerAgent(RegisterAgentModel agentModel);
  Future<void> registerClient(RegisterClientModel clientModel);
}
