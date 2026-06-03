class CartItem {
  final String id;
  final String serviceName;
  final String selectedType;
  final int quantity;
  final double pricePerUnit;
  final double totalPrice;
  final int serviceId;

  CartItem({
    required this.id,
    required this.serviceName,
    required this.selectedType,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
    required this.serviceId,
  });
}
