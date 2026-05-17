import 'package:flutter/material.dart';
import '../../domain/models/order.dart';

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [
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

  List<Order> get orders => List.unmodifiable(_orders);

  void addOrder(Order order) {
    _orders.insert(0, order);
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
      notifyListeners();
    }
  }
}
