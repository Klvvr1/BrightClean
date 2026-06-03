import 'package:flutter/foundation.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/models/review.dart';

class ReviewProvider with ChangeNotifier {
  List<Review> _reviews = [];

  ReviewProvider() {
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('reviews', orderBy: 'id DESC');
      
      if (maps.isNotEmpty) {
        _reviews = maps.map((map) => Review(
          userName: map['userName'] as String,
          comment: map['comment'] as String,
          rating: map['rating'] as double,
          serviceRating: map['serviceRating'] as double?,
          driverRating: map['driverRating'] as double?,
          date: DateTime.parse(map['date'] as String),
        )).toList();
      } else {
        _reviews = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    }
  }

  void seedDefaultReviews() {
    _reviews = [
      Review(
        userName: 'أحمد محمد',
        comment: 'خدمة ممتازة وتوصيل سريع! ملابسي عادت كأنها جديدة.',
        rating: 5.0,
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
    for (var review in _reviews) {
      _saveReviewToDb(review);
    }
  }

  Future<void> _saveReviewToDb(Review review) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('reviews', {
        'userName': review.userName,
        'comment': review.comment,
        'rating': review.rating,
        'serviceRating': review.serviceRating,
        'driverRating': review.driverRating,
        'date': review.date.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving review: $e');
    }
  }

  List<Review> get reviews => [..._reviews];

  void addReview(Review review) {
    _reviews.insert(0, review);
    _saveReviewToDb(review);
    notifyListeners();
  }
}
