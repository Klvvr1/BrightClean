import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brightcleanproject/main.dart';
import 'package:brightcleanproject/features/auth/data/providers/auth_provider.dart';
import 'package:brightcleanproject/features/customer/data/providers/order_provider.dart';
import 'package:brightcleanproject/features/customer/data/providers/review_provider.dart';
import 'package:brightcleanproject/features/customer/data/providers/cart_provider.dart';
import 'package:brightcleanproject/features/driver/data/providers/driver_provider.dart';
import 'package:brightcleanproject/features/admin/data/providers/admin_provider.dart';
import 'package:brightcleanproject/features/customer/data/providers/notification_provider.dart';

void main() {
  testWidgets('App starts and displays SplashScreen', (WidgetTester tester) async {
    // Build our app wrapped with all the necessary providers and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProxyProvider<CartProvider, OrderProvider>(
            create: (ctx) => OrderProvider(
              cartProvider: Provider.of<CartProvider>(ctx, listen: false),
            ),
            update: (ctx, cart, previous) =>
                previous ?? OrderProvider(cartProvider: cart),
          ),
          ChangeNotifierProvider(create: (_) => ReviewProvider()),
          ChangeNotifierProvider(create: (_) => DriverProvider()),
          ChangeNotifierProvider(create: (_) => AdminProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: const BrightCleanApp(),
      ),
    );
    await tester.pump(); // Start routing
    await tester.pump(const Duration(milliseconds: 100)); // Settle routing

    // Verify that the SplashScreen title is displayed.
    expect(find.text('برايت كلين'), findsOneWidget);

    // Dispose the app to clean up infinite animation controllers.
    await tester.pumpWidget(const SizedBox());
    
    // Advance fake time to flush the pending navigation timer.
    await tester.pump(const Duration(seconds: 4));
  });
}
