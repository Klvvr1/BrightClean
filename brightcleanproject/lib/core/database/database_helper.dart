import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE users (
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
  plate_number TEXT,
  commercial_reg_image_path TEXT,
  id_image_path TEXT,
  license_image_path TEXT,
  car_image_path TEXT
)
''');
    
    // Insert seed data for testing with hashed passwords
    final testUsers = [
      {'phone': '0500000000', 'password': hashPassword('Password123'), 'role': 'Admin', 'status': 'active', 'created_at': DateTime.now().toIso8601String()},
      {'phone': '0511111111', 'password': hashPassword('Password123'), 'role': 'Manager', 'status': 'active', 'created_at': DateTime.now().toIso8601String()},
      {'phone': '0522222222', 'password': hashPassword('Password123'), 'role': 'Customer', 'status': 'active', 'created_at': DateTime.now().toIso8601String()},
      {'phone': '0533333333', 'password': hashPassword('Password123'), 'role': 'Driver', 'status': 'active', 'created_at': DateTime.now().toIso8601String()},
    ];
    
    for (var user in testUsers) {
      await db.insert('users', user);
    }
  }

  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
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
    } else {
      return null;
    }
  }
}
