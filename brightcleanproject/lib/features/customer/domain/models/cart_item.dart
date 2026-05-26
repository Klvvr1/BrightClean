class CartItem {
  final String id;
  final String serviceName;
  final String selectedType;
  final int quantity;
  final double pricePerUnit;
  final double totalPrice;
  // CRIT-008: Real backend ServiceID (not a placeholder)
  final int serviceId;

  CartItem({
    required this.id,
    required this.serviceName,
    required this.selectedType,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
    this.serviceId = 1, // Default to 1 for direct-checkout services that skip the cart
  });
}
