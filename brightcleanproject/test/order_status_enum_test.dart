import 'package:brightcleanproject/core/enums/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('order status enum does not expose obsolete ironing state', () {
    expect(OrderStatus.values.map((status) => status.name),
        isNot(contains('ironing')));
  });
}
