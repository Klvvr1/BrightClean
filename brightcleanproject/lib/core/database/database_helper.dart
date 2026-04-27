import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
  phone TEXT NOT NULL,
  password TEXT NOT NULL,
  role TEXT NOT NULL
)
''');
    
    // Insert seed data for testing
    final testUsers = [
      {'phone': '0500000000', 'password': 'Password123', 'role': 'Admin'},
      {'phone': '0511111111', 'password': 'Password123', 'role': 'Manager'},
      {'phone': '0522222222', 'password': 'Password123', 'role': 'Customer'},
    ];
    
    for (var user in testUsers) {
      await db.insert('users', user);
    }
  }

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
