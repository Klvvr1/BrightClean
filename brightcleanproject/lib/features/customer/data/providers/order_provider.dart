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
  ];

  List<Order> get orders => List.unmodifiable(_orders);

  void addOrder(Order order) {
    _orders.insert(0, order);
    notifyListeners();
  }
}
