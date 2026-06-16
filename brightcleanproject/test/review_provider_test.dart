import 'package:brightcleanproject/core/network/api_client.dart';
import 'package:brightcleanproject/features/customer/data/providers/review_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeReviewApiClient extends BaseApiClient {
  FakeReviewApiClient(this.response);

  final dynamic response;
  String? requestedEndpoint;

  @override
  Future<dynamic> get(String endpoint) async {
    requestedEndpoint = endpoint;
    return response;
  }
}

void main() {
  test('ReviewProvider loads recent reviews from backend', () async {
    final apiClient = FakeReviewApiClient([
      {
        'userName': 'أحمد',
        'comment': 'خدمة ممتازة',
        'rating': 5,
        'date': '2026-06-01T10:00:00Z',
      }
    ]);
    final provider = ReviewProvider(apiClient: apiClient, autoLoad: false);

    await provider.fetchRecentReviews();

    expect(apiClient.requestedEndpoint, '/api/bookings/reviews/recent');
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
    expect(provider.reviews, hasLength(1));
    expect(provider.reviews.first.userName, 'أحمد');
    expect(provider.reviews.first.comment, 'خدمة ممتازة');
    expect(provider.reviews.first.rating, 5);
  });

  test('ReviewProvider ignores empty review comments', () async {
    final apiClient = FakeReviewApiClient([
      {
        'userName': 'أحمد',
        'comment': '',
        'rating': 5,
        'date': '2026-06-01T10:00:00Z',
      }
    ]);
    final provider = ReviewProvider(apiClient: apiClient, autoLoad: false);

    await provider.fetchRecentReviews();

    expect(provider.reviews, isEmpty);
  });
}
