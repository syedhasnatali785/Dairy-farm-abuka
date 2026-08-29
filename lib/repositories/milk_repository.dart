import 'package:dairyfarmabuka/core/database/app_database.dart';
import 'package:dairyfarmabuka/models/customer.dart';
import 'package:dairyfarmabuka/models/milk_delivery.dart';
import 'package:dairyfarmabuka/models/milk_entry.dart';
import 'package:sqflite/sqflite.dart';

class MilkRepository {
  final AppDatabase _appDatabase = AppDatabase.instance;
  Future<Database> get _db async => await _appDatabase.database;
  Future<int> insertMilkEntry(MilkEntry entry) async {
    final db = await _db;
    return await db.insert(
      'milk_entry',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveDeliveries(List<MilkDelivery> deliveries) async {
    final db = await _db;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final delivery in deliveries) {
        batch.insert('milk_delivery', delivery.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> saveDay({
    required MilkEntry entry,
    required List<Customer> customers,
    /// Map of customerId -> deliveredMilk (override). If a customer id is
    /// missing the repository will use the customer's `dailyMilk` as default.
    required Map<int, double> selectedCustomers,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      final batch = txn.batch();
      final entryId = await txn.insert('milk_entry', entry.toMap());
      for (final customer in customers) {
        final delivered = selectedCustomers[customer.id] ?? customer.dailyMilk;
        final bought = delivered > 0;
        batch.insert('milk_delivery', {
          'milkEntryId': entryId,
          'customerId': customer.id,
          'deliveredMilk': delivered,
          'pricePerLiter': customer.pricePerLiter,
          'bought': bought ? 1 : 0,
        });
      }
      await batch.commit();
    });
  }

  Future<MilkEntry?> getEntryByDate(String date) async {
    final db = await _db;
    final result = await db.query(
      'milk_entry',
      where: 'date =?',
      whereArgs: [date],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return MilkEntry.fromMap(result.first);
  }

  Future<List<MilkDelivery>> getDeliveries(int milkEntryId) async {
    final db = await _db;
    final result = await db.query(
      'milk_delivery',
      where: 'milkEntryId=?',
      whereArgs: [milkEntryId],
    );
    return result.map((e) => MilkDelivery.fromMap(e)).toList();
  }

  Future<double> soldMilk(int milkEntryId) async {
    final db = await _db;
    final result = await db.rawQuery(
      '''SELECT SUM(deliveredMilk) total FROM milk_delivery WHERE milkEntryId=?''',
      [milkEntryId],
    );
    if (result.isEmpty) return 0;
    final value = result.first['total'];
    if (value == null) return 0;
    return (value as num).toDouble();
  }

  Future<double> revenue(int milkEntryId) async {
    final db = await _db;
    final result = await db.rawQuery(
      ''' SELECT SUM(deliveredMilk * pricePerLiter) total FROM milk_delivery
      WHERE milkEntryId=? ''',
      [milkEntryId],
    );
    if (result.isEmpty) return 0;
    final value = result.first['total'];
    if (value == null) return 0;
    return (value as num).toDouble();
  }

  Future<double> remainingMilk(int milkEntryId) async {
    final db = await _db;
    final production = await db.query(
      'milk_entry',
      where: 'id=?',
      whereArgs: [milkEntryId],
      limit: 1,
    );
    if (production.isEmpty) return 0;

    final totalProduction = (production.first['totalProduction'] as num)
        .toDouble();
    final sold = await soldMilk(milkEntryId);
    return totalProduction - sold;
  }
}
