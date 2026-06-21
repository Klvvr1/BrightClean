import 'package:brightcleanproject/core/utils/general_service_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detail options in the same customer category resolve to one service', () {
    final services = {
      1: 'الملابس',
      2: 'السجاد والمفروشات',
      3: 'السيارات',
    };

    expect(resolveGeneralServiceId('الملابس', 'wash_iron', services), 1);
    expect(resolveGeneralServiceId('الملابس', 'iron_only', services), 1);
    expect(resolveGeneralServiceId('السجاد والمفروشات', 'furniture_wash', services), 2);
    expect(resolveGeneralServiceId('السيارات', 'car_full', services), 3);
  });

  test('general service names are the only registration catalog names', () {
    expect(generalServiceNames, [
      'الملابس',
      'السجاد والمفروشات',
      'السيارات',
      'تنظيف المكيفات',
      'عاملات النظافة',
      'تنظيف الخزانات',
      'غسيل الألواح الشمسية',
    ]);
  });
}
