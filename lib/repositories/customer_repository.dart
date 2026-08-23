import 'package:dairyfarmabuka/core/database/app_database.dart';
import 'package:dairyfarmabuka/models/customer.dart';
import 'package:sqflite/sqflite.dart';

class CustomerRepository {
  final AppDatabase _appDatabase = AppDatabase.instance;
  Future<Database> get _db async => await _appDatabase.database;
  Future<int> addCustomer(Customer customer) async {
    final db = await _db;
    return await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Customer>> getCustomers() async {
    final db = await _db;
    final result = await db.query(
      'customers',
      where: 'isActive =?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return result.map((e) => Customer.fromMap(e)).toList();
  }

  Future<int> setActive(int id, bool isActive) async {
    final db = await _db;
    return db.update(
      'customers',
      {'isActive': isActive ? 1 : 0},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await _db;
    final result = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Customer.fromMap(result.first);
  }

  Future<void> deleteCustomer(int id) async {
    final db = await _db;
    await db.update(
      'customers',
      {'isActive': 0},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future<int> restoreCustomer(int id) async {
    final db = await _db;
    return await db.update(
      'customers',
      {'isActive': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> customerCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      ''' SELECT COUNT(*) as total FROM Customers WHERE isActive = 1 ''',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Customer>> searchCustomers(String keyword) async {
    final db = await _db;
    final result = await db.query(
      'customers',
      where: '''isActive = 1 AND (name LIKE? OR phone LIKE?)''',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'name ASC',
    );
    return result.map((e) => Customer.fromMap(e)).toList();
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await _db;
    return db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }
}
