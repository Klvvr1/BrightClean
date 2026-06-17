import 'package:brightcleanproject/core/theme/app_theme.dart';
import 'package:brightcleanproject/core/widgets/profile/profile_menu_tile.dart';
import 'package:brightcleanproject/features/auth/presentation/role_selection_screen.dart';
import 'package:brightcleanproject/features/customer/data/providers/cart_provider.dart';
import 'package:brightcleanproject/features/customer/presentation/customer_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Future<void> pumpAtSize(
    WidgetTester tester,
    Size size,
    Widget child,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      Builder(
        builder: (context) => MaterialApp(
          theme: AppTheme.getLightTheme(context),
          home: child,
        ),
      ),
    );
    await tester.pump();
  }

  tearDown(() {});

  for (final size in const [Size(390, 844), Size(360, 800)]) {
    testWidgets('Role selection layout holds at $size', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpAtSize(tester, size, const RoleSelectionScreen());

      expect(find.text('اختر نوع الحساب'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Customer home layout holds at $size', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpAtSize(
        tester,
        size,
        ChangeNotifierProvider(
          create: (_) => CartProvider(loadFromDb: false),
          child: const CustomerHomeScreen(),
        ),
      );

      expect(find.text('برايت كلين'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Profile menu tile layout holds at $size', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpAtSize(
        tester,
        size,
        const Scaffold(
          body: ProfileMenuTile(
            icon: Icons.person_outline,
            title: 'تعديل الحساب',
            subtitle: 'تعديل بيانات الحساب الشخصي',
          ),
        ),
      );

      expect(find.text('تعديل الحساب'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
