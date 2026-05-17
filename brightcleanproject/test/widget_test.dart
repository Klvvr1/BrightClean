// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brightcleanproject/main.dart';

void main() {
  testWidgets('App starts and displays SplashScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BrightCleanApp());

    // Verify that the SplashScreen title is displayed.
    expect(find.text('برايت كلين'), findsOneWidget);

    // Dispose the app to clean up infinite animation controllers.
    await tester.pumpWidget(const SizedBox());
    
    // Advance fake time to flush the pending navigation timer.
    await tester.pump(const Duration(seconds: 4));
  });
}
