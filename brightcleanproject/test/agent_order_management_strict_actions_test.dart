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
    services: const ['غسيل'],
    status: status,
    customerLocation: 'حي الاختبار',
    time: 'الآن',
    customerName: 'عميل اختبار',
    items: [OrderItemMock('ثوب', 'غسيل', 1, Icons.local_laundry_service)],
    notes: '',
    requiresDelivery: requiresDelivery,
  );
}

void main() {
  testWidgets(
      'agent order management uses strict action button instead of a status dropdown',
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

    expect(find.byType(DropdownButtonFormField<OrderStatus>), findsNothing);
    expect(find.text('بدء المعالجة'), findsOneWidget);
  });
}
