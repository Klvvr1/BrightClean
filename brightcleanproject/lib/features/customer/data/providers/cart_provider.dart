import 'package:flutter/foundation.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/models/cart_item.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];

  CartProvider({bool loadFromDb = true}) {
    if (loadFromDb) {
      _loadCartItems();
    }
  }

  Future<void> _loadCartItems() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('cart_items');
      _items = maps
          .map((map) => CartItem(
                id: map['id'] as String,
                serviceName: map['serviceName'] as String,
                selectedType: map['selectedType'] as String,
                quantity: map['quantity'] as int,
                pricePerUnit: map['pricePerUnit'] as double,
                totalPrice: map['totalPrice'] as double,
                serviceId: map['serviceId'] as int? ?? 0,
              ))
          .toList();
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
    required int serviceId,
  }) async {
    if (quantity <= 0) throw ArgumentError('Quantity must be greater than 0');
    if (pricePerUnit < 0) {
      throw ArgumentError('Price per unit must be non-negative');
    }
    if (serviceId <= 0) {
      throw ArgumentError('A valid backend service ID is required');
    }

    final expectedTotal = quantity * pricePerUnit;
    final existingIndex = _items.indexWhere(
      (item) =>
          item.serviceName == serviceName && item.selectedType == selectedType,
    );

    if (existingIndex >= 0) {
      final oldItem = _items[existingIndex];
      _items[existingIndex] = CartItem(
        id: oldItem.id,
        serviceName: serviceName,
        selectedType: selectedType,
        quantity: oldItem.quantity + quantity,
        pricePerUnit: pricePerUnit,
        totalPrice: oldItem.totalPrice + expectedTotal,
        serviceId: serviceId,
      );
    } else {
      _items.add(CartItem(
        id: DateTime.now().toString(),
        serviceName: serviceName,
        selectedType: selectedType,
        quantity: quantity,
        pricePerUnit: pricePerUnit,
        totalPrice: expectedTotal,
        serviceId: serviceId,
      ));
    }

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
            'serviceId': item.serviceId,
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

  /// المسح العادي — يُطلق notifyListeners() لتحديث الواجهة.
  Future<void> clearCart() async {
    _items.clear();
    await _saveToDb();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // clearCartSilently — الإصلاح الجذري لمشكلة RenderBox crash
  //
  // المشكلة:
  //   submitOrder في OrderProvider يحذف cart_items من DB مباشرة
  //   بـ db.delete('cart_items') متجاوزاً CartProvider كلياً.
  //   لكن CartProvider._items لا تزال مليئة، فعند أي تفاعل لاحق
  //   يستدعي notifyListeners() ويُعيد بناء CheckoutScreen
  //   أثناء الـ navigation → RenderBox لم يُحدَّد حجمه → crash.
  //
  // الحل:
  //   استخدم هذه الدالة من submitOrder بدلاً من db.delete مباشرة.
  //   تمسح _items وتحفظ في DB لكن بدون notifyListeners() لأن
  //   CheckoutScreen ستغادر فوراً ولا يجب إعادة بنائها.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> clearCartSilently() async {
    _items.clear();
    await _saveToDb();
    // ❌ لا notifyListeners() هنا عن قصد
  }
}
