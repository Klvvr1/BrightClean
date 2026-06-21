import 'package:brightcleanproject/features/customer/data/models/booking_model.dart';
import 'package:brightcleanproject/features/customer/domain/models/order.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _bookingJson({required bool hasDeliveryTasks}) {
  return {
    'bookingID': 10,
    'clientID': 1,
    'laundryAgentID': 2,
    'addressID': 3,
    'status': 'Completed',
    'createdAt': '2026-06-20T12:00:00Z',
    'hasDeliveryTasks': hasDeliveryTasks,
    'bookingItems': const [],
  };
}

void main() {
  test('BookingModel reads delivery task presence from backend response', () {
    expect(
        BookingModel.fromJson(_bookingJson(hasDeliveryTasks: true))
            .hasDeliveryTasks,
        isTrue);
    expect(
        BookingModel.fromJson(_bookingJson(hasDeliveryTasks: false))
            .hasDeliveryTasks,
        isFalse);
  });

  test('Order driver rating flag follows actual delivery task presence', () {
    final order = Order(
      orderId: '10',
      date: '20 يونيو 2026',
      details: 'غسيل سجاد',
      status: 'تم التوصيل',
      activeStepIndex: 4,
      requiresDriverRating: false,
    );

    expect(order.requiresDriverRating, isFalse);
  });
}
