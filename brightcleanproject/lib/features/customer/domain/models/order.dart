class Order {
  final String orderId;
  final String date;
  final String details;
  final String status;
  final int activeStepIndex;
  final String? locationDescription;
  final String? paymentMethod;
  final bool isRated;
  final DateTime? pickupDate;
  final String? pickupTimeSlot;
  final String? category;

  Order({
    required this.orderId,
    required this.date,
    required this.details,
    required this.status,
    required this.activeStepIndex,
    this.locationDescription,
    this.paymentMethod,
    this.isRated = false,
    this.pickupDate,
    this.pickupTimeSlot,
    this.category,
  });

  // Determines if this order type requires driver rating
  // Returns true for clothes, carpets, and bedding services
  bool get requiresDriverRating {
    if (category == null) {
      // Fallback to string parsing for backward compatibility with existing orders
      return details.contains('ملابس') ||
          details.contains('مفروشات') ||
          details.contains('سجاد') ||
          details.contains('Bedding') ||
          details.contains('Clothes') ||
          details.contains('Carpet');
    }

    // Check category field for structured data
    final cat = category!.toLowerCase();
    return cat.contains('clothes') ||
           cat.contains('ملابس') ||
           cat.contains('carpet') ||
           cat.contains('سجاد') ||
           cat.contains('bedding') ||
           cat.contains('مفروشات');
  }
}
