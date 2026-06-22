import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OrderProvider uses maid unit only for maid services', () {
    final source = File(
      'lib/features/customer/data/providers/order_provider.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('category == 2')));
    expect(source, contains("name.contains('عاملات')"));
    expect(source, contains("name.contains('تنظيف منزل')"));
    expect(source, contains("'عاملات'"));
    expect(source, contains("'قطعة'"));
  });
}
