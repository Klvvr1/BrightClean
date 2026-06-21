import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin service type dropdown is limited to general catalog types', () {
    final source = File(
      'lib/features/admin/presentation/admin_dashboard_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('static const List<int> _generalServiceTypeValues = ['),
    );
    expect(source, contains('allowedValues: _generalServiceTypeValues'));
  });
}
