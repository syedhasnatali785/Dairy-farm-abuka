import 'package:dairyfarmabuka/core/database/app_database.dart';
import 'package:dairyfarmabuka/models/owner.dart';
import 'package:sqflite/sqlite_api.dart';

class OwnerRepository {
  OwnerRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<Database> get _db async => _appDatabase.database;

  Future<int> saveOwner(Owner owner) async {
    final db = await _db;

    return db.insert(
      'owner',
      owner.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Owner?> getOwner() async {
    final db = await _db;

    final result = await db.query('owner', limit: 1);

    if (result.isEmpty) {
      return null;
    }

    return Owner.fromMap(result.first);
  }

  Future<int> updateOwner(Owner owner) async {
    if (owner.id == null) {
      throw ArgumentError('Owner id is required to update owner.');
    }

    final db = await _db;

    return db.update(
      'owner',
      owner.toMap(),
      where: 'id = ?',
      whereArgs: [owner.id],
    );
  }

  Future<int> deleteOwner() async {
    final db = await _db;

    return db.delete('owner');
  }

  Future<bool> hasOwner() async {
    final owner = await getOwner();
    return owner != null;
  }
}
