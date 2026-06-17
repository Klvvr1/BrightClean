import 'package:brightcleanproject/features/customer/presentation/wallet_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wallet deposit uses checkout bank accounts',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WalletDetailsScreen(balance: '0 ريال يمني'),
      ),
    );

    expect(find.text('ايداع عن طريق بنك أمجاد'), findsOneWidget);
    expect(find.text('ايداع عن طريق العمقي'), findsNothing);

    await tester.tap(find.text('ايداع عن طريق بنك أمجاد'));
    await tester.pumpAndSettle();

    expect(find.text('إيداع عبر بنك أمجاد'), findsOneWidget);
    expect(find.text('124587639'), findsOneWidget);
    expect(find.text('123456789'), findsNothing);
  });
}
