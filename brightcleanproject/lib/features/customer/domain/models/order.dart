class Order {
  final String orderId;
  final String date;
  final String details;
  final String status;
  final int activeStepIndex;
  final String? locationDescription;
  final String? paymentMethod;
  final bool isRated;

  Order({
    required this.orderId,
    required this.date,
    required this.details,
    required this.status,
    required this.activeStepIndex,
    this.locationDescription,
    this.paymentMethod,
    this.isRated = false,
  });
}
