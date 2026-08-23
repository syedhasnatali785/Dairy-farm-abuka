import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dairyfarmabuka/core/database/app_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqlite_api.dart';

class SyncService {
  SyncService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  Future<Database> get _db async {
    return AppDatabase.instance.database;
  }

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _customers {
    return _firestore.collection('owners').doc(_uid).collection('customers');
  }

  Future<void> syncCustomersFromFirebase() async {
    final db = await _db;

    final snapshot = await _customers.get();

    await db.transaction((txn) async {
      for (final doc in snapshot.docs) {
        final data = doc.data();

        final firebaseId = doc.id;

        final existing = await txn.query(
          'customers',
          where: 'firebaseId = ?',
          whereArgs: [firebaseId],
          limit: 1,
        );

        final values = {
          'name': data['name'] ?? '',
          'phone': data['phone'] ?? '',
          'address': data['address'] ?? '',
          'dailyMilk': _toDouble(data['dailyMilk']),
          'pricePerLiter': _toDouble(data['pricePerLiter']),
          'customerType': data['customerType'] ?? 'DAILY',
          'isActive': data['isActive'] == true ? 1 : 0,
          'firebaseId': firebaseId,
        };

        if (existing.isEmpty) {
          await txn.insert(
            'customers',
            values,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          await txn.update(
            'customers',
            values,
            where: 'firebaseId = ?',
            whereArgs: [firebaseId],
          );
        }
      }
    });
  }

  Future<void> syncCustomersToFirebase() async {
    final db = await _db;

    final customers = await db.query('customers');

    for (final customer in customers) {
      final firebaseId = customer['firebaseId']?.toString();

      final data = {
        'name': customer['name'] ?? '',
        'phone': customer['phone'] ?? '',
        'address': customer['address'] ?? '',
        'dailyMilk': _toDouble(customer['dailyMilk']),
        'pricePerLiter': _toDouble(customer['pricePerLiter']),
        'customerType': customer['customerType'] ?? 'DAILY',
        'isActive': customer['isActive'] == 1,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (firebaseId == null || firebaseId.isEmpty) {
        final doc = await _customers.add(data);

        await db.update(
          'customers',
          {'firebaseId': doc.id},
          where: 'id = ?',
          whereArgs: [customer['id']],
        );
      } else {
        await _customers.doc(firebaseId).set(data, SetOptions(merge: true));
      }
    }
  }

  Future<void> syncCustomers() async {
    if (_auth.currentUser == null) {
      return;
    }

    await syncCustomersToFirebase();
    await syncCustomersFromFirebase();
  }

  Future<void> syncAll() async {
    if (_auth.currentUser == null) {
      return;
    }
    Future<void> syncAll() async {
      if (_auth.currentUser == null) {
        return;
      }

      try {
        await syncCustomers();
      } catch (e) {
        // Offline / Firebase error.
        //
        // App continues working from SQLite.
        //
        // We intentionally don't throw here.
        print('Sync failed: $e');
      }
    }
  }
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}
