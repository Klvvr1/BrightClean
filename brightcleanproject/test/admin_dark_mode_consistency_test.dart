import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin dashboard uses theme surfaces for dark mode consistency', () {
    final source = File(
      'lib/features/admin/presentation/admin_dashboard_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('backgroundColor: AppColors.background')));
    expect(source, isNot(contains('backgroundColor: AppColors.white')));
    expect(source, isNot(contains('fillColor: AppColors.white')));
    expect(source, isNot(contains('color: AppColors.textMain')));
    expect(source, contains('theme.scaffoldBackgroundColor'));
    expect(source, contains('theme.cardColor'));
    expect(source, contains('theme.colorScheme.surface'));
  });
}
