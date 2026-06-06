import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('brightclean.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        // Ensure database tables exist and are properly seeded on every launch
        await _ensureTablesAndSeeding(db);
      },
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final columns = await db.rawQuery("PRAGMA table_info(users)");
      final columnNames =
          columns.map((column) => column['name'] as String).toSet();

      if (columnNames.isNotEmpty) {
        if (!columnNames.contains('car_company')) {
          await db.execute("ALTER TABLE users ADD COLUMN car_company TEXT;");
        }
        if (!columnNames.contains('car_model')) {
          await db.execute("ALTER TABLE users ADD COLUMN car_model TEXT;");
        }
        if (!columnNames.contains('car_year')) {
          await db.execute("ALTER TABLE users ADD COLUMN car_year TEXT;");
        }
      }
    }

    if (oldVersion < 3) {
      final columns = await db.rawQuery("PRAGMA table_info(orders)");
      final columnNames =
          columns.map((column) => column['name'] as String).toSet();

      if (columnNames.isNotEmpty && !columnNames.contains('category')) {
        await db.execute("ALTER TABLE orders ADD COLUMN category TEXT;");
      }
    }

    // CRIT-008: Version 4 added serviceId to cart_items for real backend service IDs
    // Single rebuild check to avoid double migration
    if (oldVersion < 5) {
      final cartColumns = await db.rawQuery("PRAGMA table_info(cart_items)");
      final cartColumnNames =
          cartColumns.map((c) => c['name'] as String).toSet();

      bool needsRebuild = false;
      if (cartColumnNames.isNotEmpty) {
        // Need rebuild if upgrading from v4 or earlier
        needsRebuild = (oldVersion < 5) || (!cartColumnNames.contains('serviceId'));
      }

      if (needsRebuild) {
        await _rebuildCartItemsWithoutDefault(db);
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await _ensureTablesAndSeeding(db);
  }

  Future<void> _ensureTablesAndSeeding(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  first_name TEXT,
  father_name TEXT,
  grandfather_name TEXT,
  last_name TEXT,
  phone TEXT NOT NULL UNIQUE,
  email TEXT,
  password TEXT NOT NULL,
  gender TEXT,
  dob TEXT,
  role TEXT NOT NULL,
  address_string TEXT,
  latitude REAL,
  longitude REAL,
  status TEXT,
  created_at TEXT,
  business_name TEXT,
  selected_services TEXT,
  vehicle_type TEXT,
  car_company TEXT,
  car_model TEXT,
  car_year TEXT,
  plate_number TEXT,
  commercial_reg_image_path TEXT,
  id_image_path TEXT,
  license_image_path TEXT,
  car_image_path TEXT
)
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS orders (
  orderId TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  details TEXT NOT NULL,
  status TEXT NOT NULL,
  activeStepIndex INTEGER NOT NULL,
  locationDescription TEXT,
  paymentMethod TEXT,
  isRated INTEGER NOT NULL DEFAULT 0,
  pickupDate TEXT,
  pickupTimeSlot TEXT,
  category TEXT
)
''');

    await _createCartItemsTable(db);

    await db.execute('''
CREATE TABLE IF NOT EXISTS reviews (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userName TEXT NOT NULL,
  comment TEXT NOT NULL,
  rating REAL NOT NULL,
  serviceRating REAL,
  driverRating REAL,
  date TEXT NOT NULL
)
''');

    // Insert seed data for testing with hashed passwords if they don't already exist
    final testUsers = [
      {
        'phone': '0500000000',
        'password': hashPassword('Password123'),
        'role': 'Admin',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'phone': '0511111111',
        'password': hashPassword('Password123'),
        'role': 'Manager',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'phone': '0522222222',
        'password': hashPassword('Password123'),
        'role': 'Customer',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'phone': '0533333333',
        'password': hashPassword('Password123'),
        'role': 'Driver',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final user in testUsers) {
      final existing = await db.query(
        'users',
        where: 'phone = ?',
        whereArgs: [user['phone']],
      );

      if (existing.isEmpty) {
        await db.insert('users', user);
      }
    }
  }

  Future<void> _createCartItemsTable(DatabaseExecutor db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS cart_items (
  id TEXT PRIMARY KEY,
  serviceName TEXT NOT NULL,
  selectedType TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  pricePerUnit REAL NOT NULL,
  totalPrice REAL NOT NULL,
  serviceId INTEGER NOT NULL
)
''');
  }

  Future<void> _rebuildCartItemsWithoutDefault(DatabaseExecutor db) async {
    final cartColumns = await db.rawQuery("PRAGMA table_info(cart_items)");
    final cartColumnNames = cartColumns.map((c) => c['name'] as String).toSet();

    if (cartColumnNames.isEmpty) {
      return;
    }

    // Check for invalid serviceId rows before migration
    if (cartColumnNames.contains('serviceId')) {
      final invalidRows = await db.rawQuery(
        'SELECT COUNT(*) as count FROM cart_items WHERE serviceId IS NULL OR serviceId <= 0'
      );
      final invalidCount = invalidRows.first['count'] as int;

      if (invalidCount > 0) {
        debugPrint('ERROR: Cart migration blocked - $invalidCount cart items have invalid serviceId (NULL or <=0)');
        throw Exception(
          'Cart database upgrade cannot proceed: $invalidCount cart items have invalid or missing serviceId. '
          'Please clear your cart or contact support before upgrading.'
        );
      }
    }

    await db.execute('DROP TABLE IF EXISTS cart_items_new');
    await db.execute('''
CREATE TABLE cart_items_new (
  id TEXT PRIMARY KEY,
  serviceName TEXT NOT NULL,
  selectedType TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  pricePerUnit REAL NOT NULL,
  totalPrice REAL NOT NULL,
  serviceId INTEGER NOT NULL
)
''');

    if (cartColumnNames.contains('serviceId')) {
      // All rows are guaranteed valid by the check above
      await db.execute('''
INSERT OR REPLACE INTO cart_items_new (
  id,
  serviceName,
  selectedType,
  quantity,
  pricePerUnit,
  totalPrice,
  serviceId
)
SELECT
  id,
  serviceName,
  selectedType,
  quantity,
  pricePerUnit,
  totalPrice,
  serviceId
FROM cart_items
WHERE serviceId IS NOT NULL AND serviceId > 0
''');
    }

    await db.execute('DROP TABLE cart_items');
    await db.execute('ALTER TABLE cart_items_new RENAME TO cart_items');
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<int> registerUser(Map<String, dynamic> userData) async {
    final db = await instance.database;
    return await db.insert('users', userData);
  }

  Future<Map<String, dynamic>?> loginUser(String phone, String password) async {
    final db = await instance.database;

    final results = await db.query(
      'users',
      where: 'phone = ? AND password = ?',
      whereArgs: [phone, hashPassword(password)],
    );

    if (results.isNotEmpty) {
      return results.first;
    }

    return null;
  }
}
