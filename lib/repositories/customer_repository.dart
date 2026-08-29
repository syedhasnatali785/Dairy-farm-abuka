import 'package:dairyfarmabuka/core/database/app_database.dart';
import 'package:dairyfarmabuka/models/customer.dart';
import 'package:dairyfarmabuka/repositories/customer_repository_contract.dart';
import 'package:sqflite/sqflite.dart';

class CustomerRepository implements BaseCustomerRepository {
  final AppDatabase _appDatabase = AppDatabase.instance;

  Future<Database> get _db async => await _appDatabase.database;

  @override
  Future<int> addCustomer(Customer customer) async {
    final db = await _db;
    return await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
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

  @override
  Future<void> setActive(Object id, bool isActive) async {
    final db = await _db;
    final customerId = _requireIntId(id);
    await db.update(
      'customers',
      {'isActive': isActive ? 1 : 0},
      where: 'id=?',
      whereArgs: [customerId],
    );
  }

  @override
  Future<Customer?> getCustomerById(Object id) async {
    final db = await _db;
    final customerId = _requireIntId(id);
    final result = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Customer.fromMap(result.first);
  }

  @override
  Future<void> deleteCustomer(Object id) async {
    final db = await _db;
    final customerId = _requireIntId(id);
    await db.update(
      'customers',
      {'isActive': 0},
      where: 'id=?',
      whereArgs: [customerId],
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

  @override
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

  @override
  Future<void> updateCustomer(Customer customer, {Object? id}) async {
    final db = await _db;
    final customerId = customer.id ?? _requireIntId(id);
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  int _requireIntId(Object? id) {
    if (id is int) return id;
    if (id is String) {
      final parsed = int.tryParse(id);
      if (parsed != null) return parsed;
    }
    throw StateError('SQLite customer id must be an integer. Got: $id');
  }
}
