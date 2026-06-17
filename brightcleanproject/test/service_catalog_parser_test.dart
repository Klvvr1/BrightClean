import 'package:brightcleanproject/features/auth/data/utils/service_catalog_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads catalog services from direct list response', () {
    final services = parseServiceCatalogItems([
      {'serviceID': 1, 'serviceName': 'غسيل'},
      {'serviceId': '2', 'ServiceName': 'كوي'},
    ]);

    expect(services, {
      1: 'غسيل',
      2: 'كوي',
    });
  });

  test('reads catalog services from wrapped response', () {
    final services = parseServiceCatalogItems({
      'value': [
        {'ServiceID': 3, 'ServiceName': 'تنظيف جاف'},
      ],
    });

    expect(services, {
      3: 'تنظيف جاف',
    });
  });

  test('ignores invalid catalog rows', () {
    final services = parseServiceCatalogItems({
      'services': [
        {'serviceID': 0, 'serviceName': 'غير صالح'},
        {'serviceID': 4, 'serviceName': ''},
        {'id': 5, 'name': 'سجاد'},
      ],
    });

    expect(services, {
      5: 'سجاد',
    });
  });
}
