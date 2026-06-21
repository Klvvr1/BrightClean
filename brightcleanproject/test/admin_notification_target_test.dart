import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin notification dialog includes all users target', () {
    final source = File(
      'lib/features/admin/presentation/admin_dashboard_screen.dart',
    ).readAsStringSync();

    expect(source, contains("DropdownMenuItem(value: 'All'"));
  });
}
