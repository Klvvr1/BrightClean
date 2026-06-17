import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/user_error_message.dart';
import '../../data/models/register_agent_model.dart';
import '../../data/models/register_client_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../repositories/auth_repository_impl.dart';
import '../../../customer/data/providers/cart_provider.dart';
import '../../../customer/data/providers/order_provider.dart';
import '../../../../core/network/api_client.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  final FlutterSecureStorage _secureStorage;
  final BaseApiClient _apiClient;

  String? _token;
  int? _userId;
  String? _role;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({
    AuthRepository? authRepository,
    FlutterSecureStorage? secureStorage,
    BaseApiClient? apiClient,
  })  : _authRepository = authRepository ?? AuthRepositoryImpl(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _apiClient = apiClient ?? BaseApiClient() {
    _loadSession();
  }

  String? get token => _token;
  int? get userId => _userId;
  String? get role => _role;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = await _secureStorage.read(key: 'auth_token');

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

      // Check System Status before persisting login (except for Admins)
      if (response.role.toLowerCase() != 'admin') {
        try {
          final data = await _apiClient.get('/api/systemstatus/status');
          final isLoginEnabled = data['loginEnabled'] ?? true;
          if (!isLoginEnabled) {
            throw ServerException(
                message: data['message'] ??
                    'النظام تحت الصيانة. يرجى المحاولة لاحقاً.');
          }
        } on ServerException {
          rethrow;
        } catch (e) {
          debugPrint('Error checking system status during login: $e');
          throw ServerException(
              message: 'فشل التحقق من حالة النظام. يرجى المحاولة لاحقاً.');
        }
      }

      // Await all persistence operations before mutating memory state
      final prefs = await SharedPreferences.getInstance();
      await _secureStorage.write(key: 'auth_token', value: response.token);
      await prefs.setInt('user_id', response.userId);
      await prefs.setString('user_role', response.role);
      await prefs.setString('user_email', response.email);
      await prefs.setString(
          'user_name', '${response.firstName} ${response.lastName}'.trim());
      await prefs.setString('user_phone', response.phoneNo);

      // Mutate variables only after successful persistence
      _token = response.token;
      _userId = response.userId;
      _role = response.role;

      _isLoading = false;
      notifyListeners();
    } on ServerException catch (e) {
      _errorMessage = userMessageFromError(e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      _isLoading = false;
      notifyListeners();
      debugPrint('Login failed: $e');
      throw ServerException(message: _errorMessage);
    }
  }

  Future<void> registerAgent(
    RegisterAgentModel model, {
    required String commercialRegisterImagePath,
    required String nationalIdImagePath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.registerAgent(
        model,
        commercialRegisterImagePath: commercialRegisterImagePath,
        nationalIdImagePath: nationalIdImagePath,
      );
      _isLoading = false;
      notifyListeners();
    } on ServerException catch (e) {
      _errorMessage = userMessageFromError(e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      _isLoading = false;
      notifyListeners();
      debugPrint('Agent registration failed: $e');
      throw ServerException(message: _errorMessage);
    }
  }

  Future<void> registerClient(RegisterClientModel model) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.registerClient(model);
      _isLoading = false;
      notifyListeners();
    } on ServerException catch (e) {
      _errorMessage = userMessageFromError(e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      _isLoading = false;
      notifyListeners();
      debugPrint('Client registration failed: $e');
      throw ServerException(message: _errorMessage);
    }
  }

  Future<void> logout(
      [CartProvider? cartProvider, OrderProvider? orderProvider]) async {
    try {
      // Delete token from secure storage first
      await _secureStorage.delete(key: 'auth_token');

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_role');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('refresh_token');
      await prefs.remove('wallet_balance');
      await prefs.remove('profile_image_path');
      await prefs.remove('user_name_is_default');
      await prefs.remove('user_phone');
      // For clean migration, remove any legacy plain text token key
      await prefs.remove('auth_token');

      // Reset state
      _token = null;
      _userId = null;
      _role = null;
      _errorMessage = null;

      if (cartProvider != null) {
        await cartProvider.clearCart();
      }

      if (orderProvider != null) {
        await orderProvider.clearOrders();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error performing logout: $e');
    }
  }

  Future<String> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final otp = await _authRepository.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return otp;
    } on ServerException catch (e) {
      _errorMessage = userMessageFromError(e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      _isLoading = false;
      notifyListeners();
      debugPrint('Forgot password failed: $e');
      throw ServerException(message: _errorMessage);
    }
  }

  Future<void> resetPassword(
      String email, String token, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.resetPassword(email, token, newPassword);
      _isLoading = false;
      notifyListeners();
    } on ServerException catch (e) {
      _errorMessage = userMessageFromError(e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      _isLoading = false;
      notifyListeners();
      debugPrint('Reset password failed: $e');
      throw ServerException(message: _errorMessage);
    }
  }

  Future<void> updateProfile(String name, String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final parts = name.trim().split(' ');
      final firstName = parts.isNotEmpty ? parts[0] : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      await _authRepository.updateProfile(firstName, lastName, phone);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      await prefs.setString('user_phone', phone);

      _isLoading = false;
      notifyListeners();
    } on ServerException catch (e) {
      _errorMessage = userMessageFromError(e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      _isLoading = false;
      notifyListeners();
      debugPrint('Profile update failed: $e');
      throw ServerException(message: _errorMessage);
    }
  }
}
