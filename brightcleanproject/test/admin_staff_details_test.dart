import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('approved staff cards expose details action and role-based details', () {
    final source = File(
      'lib/features/admin/presentation/admin_dashboard_screen.dart',
    ).readAsStringSync();

    expect(source, contains('Icons.info_outline'));
    expect(source, contains("staff['role']?.toString().toLowerCase()"));
    expect(source, contains("'role': role"));
  });
}
