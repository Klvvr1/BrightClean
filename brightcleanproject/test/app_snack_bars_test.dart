import 'package:brightcleanproject/core/widgets/app_snack_bars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cart success snackbar auto-closes with accessibility enabled',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(accessibleNavigation: true),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                AppSnackBars.showCartSuccess(
                  ScaffoldMessenger.of(context),
                  onViewCart: () {},
                  duration: const Duration(milliseconds: 50),
                );
              },
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();

    expect(find.text(AppSnackBars.cartSuccessMessage), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();

    expect(find.text(AppSnackBars.cartSuccessMessage), findsNothing);
  });
}
