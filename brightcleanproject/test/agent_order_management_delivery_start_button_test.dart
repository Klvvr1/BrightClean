import 'package:brightcleanproject/core/enums/laundry_type.dart';
import 'package:brightcleanproject/core/enums/order_status.dart';
import 'package:brightcleanproject/features/agent/presentation/agent_dashboard_screen.dart';
import 'package:brightcleanproject/features/agent/presentation/agent_order_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AgentOrderModel _order(OrderStatus status, {bool requiresDelivery = true}) {
  return AgentOrderModel(
    id: '42',
    laundryType: LaundryType.clothes,
    services: const ['Wash'],
    status: status,
    customerLocation: 'Test area',
    time: 'Now',
    customerName: 'Test client',
    items: [
      OrderItemMock('Item', 'Wash', 1, Icons.local_laundry_service),
    ],
    notes: '',
    requiresDelivery: requiresDelivery,
  );
}

void main() {
  testWidgets('start processing is disabled until delivery reaches laundry',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AgentOrderManagementScreen(
          orderId: '42',
          initialStatus: OrderStatus.received,
          order: _order(OrderStatus.received),
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));

    expect(button.onPressed, isNull);
  });

  testWidgets('start processing remains enabled for non delivery orders',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AgentOrderManagementScreen(
          orderId: '42',
          initialStatus: OrderStatus.received,
          order: _order(OrderStatus.received, requiresDelivery: false),
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));

    expect(button.onPressed, isNotNull);
  });
}
