class Review {
  final String userName;
  final String comment;
  final double rating;
  final double? serviceRating;
  final double? driverRating;
  final DateTime date;

  Review({
    required this.userName,
    required this.comment,
    required this.rating,
    this.serviceRating,
    this.driverRating,
    required this.date,
  }) {
    // Validate ratings are finite and within valid range
    if (!rating.isFinite || rating < 0 || rating > 5) {
      throw ArgumentError('Rating must be a finite number between 0 and 5');
    }
    if (serviceRating != null && (!serviceRating!.isFinite || serviceRating! < 0 || serviceRating! > 5)) {
      throw ArgumentError('Service rating must be a finite number between 0 and 5');
    }
    if (driverRating != null && (!driverRating!.isFinite || driverRating! < 0 || driverRating! > 5)) {
      throw ArgumentError('Driver rating must be a finite number between 0 and 5');
    }
  }
}
