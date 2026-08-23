import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'dairy_farm.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(''' CREATE TABLE owner(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        farmName TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        prediction REAL NOT NULL
      ); 
      ''');
    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        dailyMilk REAL NOT NULL,
        pricePerLiter REAL NOT NULL,
        customerType TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      );

 ''');

    await db.execute('''
     CREATE TABLE milk_entry(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        totalProduction REAL NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE milk_delivery(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        milkEntryId INTEGER NOT NULL,
        customerId INTEGER NOT NULL,
        deliveredMilk REAL NOT NULL,
        pricePerLiter REAL NOT NULL,
        bought INTEGER NOT NULL,

        FOREIGN KEY(milkEntryId)
          REFERENCES milk_entry(id)
          ON DELETE CASCADE,

        FOREIGN KEY(customerId)
          REFERENCES customers(id)
          ON DELETE CASCADE
      );
    ''');
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
