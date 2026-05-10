class Order {
  final String orderId;
  final String date;
  final String details;
  final String status;
  final int activeStepIndex;

  Order({
    required this.orderId,
    required this.date,
    required this.details,
    required this.status,
    required this.activeStepIndex,
  });
}
