import 'package:brightcleanproject/core/database/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('cart_items serviceId has no fallback default', () async {
    final db = await DatabaseHelper.instance.database;
    final columns = await db.rawQuery('PRAGMA table_info(cart_items)');
    final serviceIdColumn = columns.firstWhere(
      (column) => column['name'] == 'serviceId',
    );

    expect(serviceIdColumn['notnull'], 1);
    expect(serviceIdColumn['dflt_value'], isNull);
  });
}
