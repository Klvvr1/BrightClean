import 'package:brightcleanproject/core/theme/app_theme.dart';
import 'package:brightcleanproject/features/auth/presentation/driver_registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('driver registration does not ask for location',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (context) => MaterialApp(
          theme: AppTheme.getLightTheme(context),
          home: const DriverRegistrationScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('حدد الموقع على الخريطة'), findsNothing);
  });
}
