import 'package:brightcleanproject/features/customer/data/providers/cart_provider.dart';
import 'package:brightcleanproject/features/customer/data/providers/order_provider.dart';
import 'package:brightcleanproject/features/customer/presentation/checkout_screen.dart';
import 'package:brightcleanproject/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Checkout screen lays out without RenderBox errors',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cartProvider = CartProvider(loadFromDb: false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
          ChangeNotifierProvider(
            create: (_) => OrderProvider(
              cartProvider: cartProvider,
              initialize: false,
            ),
          ),
        ],
        child: Builder(
          builder: (context) => MaterialApp(
            theme: AppTheme.getLightTheme(context),
            home: const CheckoutScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
