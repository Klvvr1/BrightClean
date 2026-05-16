import 'package:flutter/foundation.dart';
import '../../domain/models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => [..._items];

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    for (var item in _items) {
      total += item.totalPrice;
    }
    return total;
  }

  void addItem({
    required String serviceName,
    required String selectedType,
    required int quantity,
    required double pricePerUnit,
    required double totalPrice,
  }) {
    // Validate inputs
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than 0');
    }
    if (pricePerUnit < 0) {
      throw ArgumentError('Price per unit must be non-negative');
    }

    // Compute expected total internally (do not trust caller-supplied totalPrice)
    final expectedTotal = quantity * pricePerUnit;

    // Check if same service and type already in cart
    final existingIndex = _items.indexWhere(
      (item) => item.serviceName == serviceName && item.selectedType == selectedType
    );

    if (existingIndex >= 0) {
      // Update existing item
      final oldItem = _items[existingIndex];
      final newQuantity = oldItem.quantity + quantity;
      final newTotal = oldItem.totalPrice + expectedTotal;
      _items[existingIndex] = CartItem(
        id: oldItem.id,
        serviceName: serviceName,
        selectedType: selectedType,
        quantity: newQuantity,
        pricePerUnit: pricePerUnit,
        totalPrice: newTotal,
      );
    } else {
      // Add new item
      _items.add(
        CartItem(
          id: DateTime.now().toString(),
          serviceName: serviceName,
          selectedType: selectedType,
          quantity: quantity,
          pricePerUnit: pricePerUnit,
          totalPrice: expectedTotal,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
