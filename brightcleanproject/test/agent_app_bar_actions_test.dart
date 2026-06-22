import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('agent order app bar actions do not include theme or notification buttons', () {
    final source = File(
      'lib/features/agent/presentation/widgets/agent_app_bar_actions.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('toggleTheme()')));
    expect(source, isNot(contains('NotificationProvider')));
    expect(source, isNot(contains('Icons.notifications_outlined')));
    expect(source, isNot(contains('Icons.dark_mode')));
    expect(source, isNot(contains('Icons.light_mode')));
  });
}
