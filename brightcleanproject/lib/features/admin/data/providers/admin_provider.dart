import 'package:flutter/foundation.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../models/pending_user_model.dart';

class AdminProvider with ChangeNotifier {
  final AdminRepository adminRepository;

  List<PendingUserModel> _pendingUsers = [];
  List<dynamic> _approvedStaff = [];
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;

  AdminProvider({AdminRepository? adminRepository})
      : adminRepository = adminRepository ?? AdminRepositoryImpl();

  List<PendingUserModel> get pendingUsers => _pendingUsers;
  List<dynamic> get approvedStaff => _approvedStaff;
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchApprovedStaff() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _approvedStaff = await adminRepository.getApprovedStaff();
    } on ServerException catch (e) {
      _errorMessage = e.message ?? 'حدث خطأ أثناء تحميل الموظفين المعتمدين';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPendingUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pendingUsers = await adminRepository.getPendingApprovals();
    } on ServerException catch (e) {
      _errorMessage = e.message ?? 'حدث خطأ أثناء تحميل الطلبات المعلقة';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveUser(int userId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await adminRepository.approveUser(userId);
    } on ServerException catch (e) {
      _errorMessage = e.message ?? 'حدث خطأ أثناء الموافقة على المستخدم';
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    }

    try {
      await fetchPendingUsers();
    } catch (e) {
      debugPrint('Error refreshing pending users after approval: $e');
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }
}
