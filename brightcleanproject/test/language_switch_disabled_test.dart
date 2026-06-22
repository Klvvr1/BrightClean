import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('language switch controls are disabled in role profile screens', () {
    final files = [
      'lib/features/customer/presentation/customer_profile_screen.dart',
      'lib/features/driver/presentation/driver_dashboard_screen.dart',
      'lib/features/agent/presentation/agent_dashboard_screen.dart',
    ];

    for (final path in files) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('toggleLanguage()')), reason: path);
      expect(source, contains('onTap: null'), reason: path);
    }
  });
}
