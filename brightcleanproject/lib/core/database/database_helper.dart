import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart'; // Needed for debugPrint
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase('brightclean.db');
    return _database!;
  }

  Future<Database> _initDatabase(String filePath) async {
    try {
      if (kIsWeb) {
        // 1. Cross-Platform Support: Web Implementation
        // Explicitly set the options to point to the local file
        var factory = createDatabaseFactoryFfiWeb(
          options: SqfliteFfiWebOptions(sharedWorkerUri: Uri.parse('sqflite_sw.js')),
        );
        databaseFactory = factory;

        return await factory.openDatabase(
          filePath,
          options: OpenDatabaseOptions(
            version: 2,
            onCreate: _createDB,
            onUpgrade: _upgradeDB,
          ),
        ).timeout(const Duration(seconds: 15), onTimeout: () {
          print("ERROR: Service worker initialization timed out or failed to connect.");
          throw Exception("خطأ في تهيئة قاعدة البيانات - تأكد من رسائل F12 (Service Worker Timeout)");
        });
      } else {
        // 2. Cross-Platform Support: Mobile Implementation
        final dbPath = await getDatabasesPath();
        final path = join(dbPath, filePath);

        return await openDatabase(
          path,
          version: 2,
          onCreate: _createDB,
          onUpgrade: _upgradeDB,
        );
      }
    } catch (e) {
      debugPrint("Database initialization error: $e");
      if (kIsWeb) {
        debugPrint("CRITICAL WEB ERROR: sqflite_sw.js may be missing! Please run 'dart run sqflite_common_ffi_web:setup' in your terminal and restart the app.");
      }
      rethrow;
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Drop existing table and recreate it with the new schema for development purposes
    await db.execute('DROP TABLE IF EXISTS users');
    await _createDB(db, newVersion);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  first_name TEXT,
  last_name TEXT,
  phone TEXT NOT NULL,
  email TEXT,
  password TEXT NOT NULL,
  gender TEXT,
  dob TEXT,
  role TEXT NOT NULL
)
''');
    
    // Insert seed data
    await db.insert('users', {
      'first_name': 'عميل',
      'last_name': 'تجريبي',
      'phone': '0500000000',
      'email': 'customer@test.com',
      'password': 'password1234',
      'gender': 'M',
      'dob': '2000-01-01',
      'role': 'customer',
    });
  }

  // Registration logic: Database insertion mapping
  Future<int> registerUser(Map<String, dynamic> userData) async {
    final db = await instance.database;
    return await db.insert('users', userData);
  }

  // Login logic
  Future<Map<String, dynamic>?> loginUser(String phone, String password) async {
    final db = await instance.database;
    final results = await db.query(
      'users',
      where: 'phone = ? AND password = ?',
      whereArgs: [phone, password],
    );

    if (results.isNotEmpty) {
      return results.first;
    } else {
      return null;
    }
  }
}
