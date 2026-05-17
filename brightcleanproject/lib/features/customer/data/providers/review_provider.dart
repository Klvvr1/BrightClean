import 'package:flutter/foundation.dart';
import '../../domain/models/review.dart';

class ReviewProvider with ChangeNotifier {
  final List<Review> _reviews = [
    Review(
      userName: 'أحمد محمد',
      comment: 'خدمة ممتازة وتوصيل سريع! ملابسي عادت كأنها جديدة.',
      rating: 5.0,
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  List<Review> get reviews => [..._reviews];

  void addReview(Review review) {
    _reviews.insert(0, review);
    notifyListeners();
  }
}
