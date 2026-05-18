import 'package:flutter/foundation.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/models/cart_item.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];

  CartProvider() {
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('cart_items');
      _items = maps.map((map) => CartItem(
        id: map['id'] as String,
        serviceName: map['serviceName'] as String,
        selectedType: map['selectedType'] as String,
        quantity: map['quantity'] as int,
        pricePerUnit: map['pricePerUnit'] as double,
        totalPrice: map['totalPrice'] as double,
      )).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cart items: $e');
    }
  }

  List<CartItem> get items => [..._items];

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    for (var item in _items) {
      total += item.totalPrice;
    }
    return total;
  }

  Future<void> addItem({
    required String serviceName,
    required String selectedType,
    required int quantity,
    required double pricePerUnit,
    required double totalPrice,
  }) async {
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
    
    // Persist to DB
    await _saveToDb();
    notifyListeners();
  }

  Future<void> _saveToDb() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        await txn.delete('cart_items');
        for (var item in _items) {
          await txn.insert('cart_items', {
            'id': item.id,
            'serviceName': item.serviceName,
            'selectedType': item.selectedType,
            'quantity': item.quantity,
            'pricePerUnit': item.pricePerUnit,
            'totalPrice': item.totalPrice,
          });
        }
      });
    } catch (e) {
      debugPrint('Error saving cart items: $e');
    }
  }

  Future<void> removeItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    await _saveToDb();
    notifyListeners();
  }

  Future<void> clearCart() async {
    _items.clear();
    await _saveToDb();
    notifyListeners();
  }
}
