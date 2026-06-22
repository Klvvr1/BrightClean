import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/user_error_message.dart';
import '../../../../core/network/api_client.dart';

class WalletProvider with ChangeNotifier {
  final BaseApiClient _apiClient;

  double _balance = 0.0;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  WalletProvider({BaseApiClient? apiClient})
      : _apiClient = apiClient ?? BaseApiClient();

  double get balance => _balance;
  String get balanceFormatted => '${_balance.toStringAsFixed(2)} ريال';
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  /// جلب الرصيد من الـ Backend وتحديث الـ cache المحلي
  Future<void> fetchBalance() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/api/wallet/balance');
      if (response is Map<String, dynamic>) {
        final raw = response['balance'] ?? response['Balance'] ?? 0;
        _balance = (raw is num) ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0.0;
      } else if (response is num) {
        _balance = response.toDouble();
      }
      // حفظ نسخة cache محلية لعرضها فوراً في الجلسة القادمة
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wallet_balance', balanceFormatted);
      debugPrint('💰 WalletProvider: balance fetched = $_balance ريال');
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      debugPrint('💰 WalletProvider: fetchBalance failed: $e');
      // Fallback: اقرأ من الـ cache المحلي إذا فشل الـ API
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('wallet_balance');
      if (cached != null) {
        final match = RegExp(r'[\d.]+').firstMatch(cached);
        if (match != null) _balance = double.tryParse(match.group(0)!) ?? 0.0;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// إرسال طلب الإيداع مع صورة السند إلى الـ Backend
  /// يرفع: المبلغ + رقم العملية + ملف السند (multipart)
  /// عند النجاح: يعيد جلب الرصيد المحدَّث من الـ Backend
  Future<void> submitDeposit({
    required double amount,
    required String proofFilePath,
    String? operationNumber,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fields = <String, String>{
        'amount': amount.toStringAsFixed(2),
        if (operationNumber != null && operationNumber.isNotEmpty)
          'operationNumber': operationNumber,
      };

      final files = <http.MultipartFile>[
        await http.MultipartFile.fromPath('proofFile', proofFilePath),
      ];

      await _apiClient.postMultipart(
        '/api/wallet/deposit',
        fields: fields,
        files: files,
      );

      debugPrint('💰 WalletProvider: deposit submitted: amount=$amount, op=$operationNumber');

      // تحديث الرصيد من الـ Backend بعد نجاح الإيداع
      await fetchBalance();
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      debugPrint('💰 WalletProvider: submitDeposit failed: $e');
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
