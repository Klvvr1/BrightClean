import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/models/order.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];

  OrderProvider() {
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('orders', orderBy: 'date DESC');
      
      if (maps.isNotEmpty) {
        _orders = maps.map((map) => Order(
          orderId: map['orderId'] as String,
          date: map['date'] as String,
          details: map['details'] as String,
          status: map['status'] as String,
          activeStepIndex: map['activeStepIndex'] as int,
          locationDescription: map['locationDescription'] as String?,
          paymentMethod: map['paymentMethod'] as String?,
          isRated: (map['isRated'] as int) == 1,
          pickupDate: map['pickupDate'] != null ? DateTime.parse(map['pickupDate'] as String) : null,
          pickupTimeSlot: map['pickupTimeSlot'] as String?,
        )).toList();
      } else {
        // Seed default orders if empty
        _seedDefaultOrders();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading orders: $e');
    }
  }

  void _seedDefaultOrders() {
    _orders = [
      Order(
        orderId: '1025',
        date: '16 أبريل 2026',
        details: 'تنظيف سجاد - 2 قطعة',
        status: 'قيد الانتظار',
        activeStepIndex: 0,
      ),
      Order(
        orderId: '1024',
        date: '15 أبريل 2026',
        details: 'غسيل ملابس - 5 قطع',
        status: 'في الطريق',
        activeStepIndex: 1,
      ),
      Order(
        orderId: '1023',
        date: '14 أبريل 2026',
        details: 'غسيل سيارة - كبيرة',
        status: 'تم التوصيل',
        activeStepIndex: 4,
      ),
    ];
    for (var order in _orders) {
      _saveOrderToDb(order);
    }
  }

  Future<void> _saveOrderToDb(Order order) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('orders', {
        'orderId': order.orderId,
        'date': order.date,
        'details': order.details,
        'status': order.status,
        'activeStepIndex': order.activeStepIndex,
        'locationDescription': order.locationDescription,
        'paymentMethod': order.paymentMethod,
        'isRated': order.isRated ? 1 : 0,
        'pickupDate': order.pickupDate?.toIso8601String(),
        'pickupTimeSlot': order.pickupTimeSlot,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('Error saving order: $e');
    }
  }

  List<Order> get orders => List.unmodifiable(_orders);

  void addOrder(Order order) {
    _orders.insert(0, order);
    _saveOrderToDb(order);
    notifyListeners();
  }

  void markOrderAsRated(String orderId) {
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index != -1) {
      final oldOrder = _orders[index];
      _orders[index] = Order(
        orderId: oldOrder.orderId,
        date: oldOrder.date,
        details: oldOrder.details,
        status: oldOrder.status,
        activeStepIndex: oldOrder.activeStepIndex,
        locationDescription: oldOrder.locationDescription,
        paymentMethod: oldOrder.paymentMethod,
        isRated: true,
      );
      _saveOrderToDb(_orders[index]);
      notifyListeners();
    }
  }
}
