import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../../data/models/register_agent_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../repositories/auth_repository_impl.dart';
import '../../../customer/data/providers/cart_provider.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;

  String? _token;
  int? _userId;
  String? _role;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepositoryImpl() {
    _loadSession();
  }

  String? get token => _token;
  int? get userId => _userId;
  String? get role => _role;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      
      final rawUserId = prefs.get('user_id');
      if (rawUserId is int) {
        _userId = rawUserId;
      } else if (rawUserId is String) {
        _userId = int.tryParse(rawUserId);
      }
      
      _role = prefs.getString('user_role');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading auth session: $e');
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authRepository.login(email, password);
      
      _token = response.token;
      _userId = response.userId;
      _role = response.role;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', response.token);
      await prefs.setInt('user_id', response.userId);
      await prefs.setString('user_role', response.role);
      await prefs.setString('user_email', response.email);
      await prefs.setString('user_name', '${response.firstName} ${response.lastName}'.trim());

      _isLoading = false;
      notifyListeners();
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      throw ServerException(message: e.toString());
    }
  }

  Future<void> registerAgent(RegisterAgentModel model) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.registerAgent(model);
      _isLoading = false;
      notifyListeners();
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      throw ServerException(message: e.toString());
    }
  }

  Future<void> logout([CartProvider? cartProvider]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_role');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('refresh_token');
      await prefs.remove('wallet_balance');
      await prefs.remove('profile_image_path');
      await prefs.remove('user_name_is_default');
      await prefs.remove('user_phone');

      _token = null;
      _userId = null;
      _role = null;
      _errorMessage = null;

      if (cartProvider != null) {
        await cartProvider.clearCart();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error performing logout: $e');
    }
  }
}
