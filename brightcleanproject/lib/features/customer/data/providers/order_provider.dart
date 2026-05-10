import 'package:flutter/material.dart';
import '../../domain/models/order.dart';
import '../../../../core/theme/app_colors.dart';

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [
    Order(
      orderId: '1025',
      date: '16 أبريل 2026',
      details: 'تنظيف سجاد - 2 قطعة',
      status: 'قيد الانتظار',
      statusColor: AppColors.warning,
      activeStepIndex: 0,
    ),
    Order(
      orderId: '1024',
      date: '15 أبريل 2026',
      details: 'غسيل ملابس - 5 قطع',
      status: 'في الطريق',
      statusColor: AppColors.warning,
      activeStepIndex: 1,
    ),
  ];

  List<Order> get orders => _orders;

  void addOrder(Order order) {
    _orders.insert(0, order);
    notifyListeners();
  }
}
