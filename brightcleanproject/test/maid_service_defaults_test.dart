import 'package:brightcleanproject/features/customer/presentation/service_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('maid service starts without preselected values', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ServiceDetailsScreen(serviceType: 'عاملات النظافة'),
      ),
    );

    expect(find.text('عدد الساعات المطلوبة'), findsOneWidget);
    expect(find.text('عدد العاملات المطلوبة'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));

    await tester.tap(find.text('إتمام الطلب'));
    await tester.pump();

    expect(
      find.text('يرجى تحديد عدد الساعات وعدد العاملات'),
      findsOneWidget,
    );
  });
}
