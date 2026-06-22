import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('driver tracking map fallback defaults to Mukalla, Yemen', () {
    final source = File(
      'lib/features/driver/presentation/driver_tracking_screen.dart',
    ).readAsStringSync();

    expect(source, contains('LatLng(14.493329, 49.057153)'));
    expect(source, isNot(contains('LatLng(24.7136, 46.6753)')));
  });
}
