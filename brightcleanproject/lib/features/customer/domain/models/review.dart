class Review {
  final String userName;
  final String comment;
  final double rating;
  final DateTime date;

  Review({
    required this.userName,
    required this.comment,
    required this.rating,
    required this.date,
  }) {
    // Validate rating is finite and within valid range
    if (!rating.isFinite || rating < 0 || rating > 5) {
      throw ArgumentError('Rating must be a finite number between 0 and 5');
    }
  }
}
