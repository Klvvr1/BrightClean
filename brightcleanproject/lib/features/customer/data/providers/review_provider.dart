import 'package:flutter/foundation.dart';
import '../../../../core/error/user_error_message.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/review.dart';

class ReviewProvider with ChangeNotifier {
  final BaseApiClient _apiClient;
  List<Review> _reviews = [];
  bool _isLoading = false;
  String? _errorMessage;

  ReviewProvider({BaseApiClient? apiClient, bool autoLoad = true})
      : _apiClient = apiClient ?? BaseApiClient() {
    if (autoLoad) {
      fetchRecentReviews();
    }
  }

  List<Review> get reviews => [..._reviews];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRecentReviews() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/api/bookings/reviews/recent');
      _reviews = response is List
          ? response
              .whereType<Map>()
              .map((item) => item.map(
                    (key, value) => MapEntry(key.toString(), value),
                  ))
              .map((item) => Review(
                    userName: item['userName']?.toString() ?? 'مستخدم',
                    comment: item['comment']?.toString() ?? '',
                    rating: (item['rating'] as num?)?.toDouble() ?? 0.0,
                    date: DateTime.tryParse(item['date']?.toString() ?? '') ??
                        DateTime.now(),
                  ))
              .where((review) => review.comment.trim().isNotEmpty)
              .toList()
          : [];
    } catch (e) {
      _errorMessage = userMessageFromError(e);
      debugPrint('Error loading reviews from API: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}
