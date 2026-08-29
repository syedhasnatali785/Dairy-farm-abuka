import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/database/app_database.dart';

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final AppDatabase _database = AppDatabase.instance;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isSyncing = false;

  Future<void> initialize() async {
    await _syncIfOnline();

    _connectivitySubscription ??= Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      final online = results.any((result) => result != ConnectivityResult.none);

      if (online) {
        await _syncIfOnline();
      }
    });
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  Future<void> syncNow() async {
    await _syncIfOnline();
  }

  Future<void> syncAll() async {
    await _syncIfOnline();
  }

  Future<void> _syncIfOnline() async {
    if (_isSyncing) return;

    final user = _auth.currentUser;

    if (user == null) return;

    final connectivity = await Connectivity().checkConnectivity();

    final online = connectivity.any(
      (result) => result != ConnectivityResult.none,
    );

    if (!online) return;

    _isSyncing = true;

    try {
      await _syncOwner(user.uid);
      await _syncCustomers(user.uid);
      await _syncMilkEntries(user.uid);
      await _syncMilkDeliveries(user.uid);
    } catch (e, stackTrace) {
      debugPrint('Sync error: $e\n$stackTrace');
    } finally {
      _isSyncing = false;
    }
  }

  // ===========================================================
  // OWNER
  // ===========================================================

  Future<void> _syncOwner(String uid) async {
    final db = await _database.database;

    final rows = await db.query('owner', limit: 1);

    if (rows.isEmpty) return;

    final owner = rows.first;

    final doc = _firestore
        .collection('users')
        .doc(uid)
        .collection('owner')
        .doc('profile');

    await doc.set({
      'id': owner['id'],
      'name': owner['name'],
      'farmName': owner['farmName'],
      'phone': owner['phone'],
      'address': owner['address'],
      'prediction': owner['prediction'],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ===========================================================
  // CUSTOMERS
  // ===========================================================

  Future<void> _syncCustomers(String uid) async {
    final db = await _database.database;

    final customers = await db.query('customers');

    final batch = _firestore.batch();

    final collection = _firestore
        .collection('users')
        .doc(uid)
        .collection('customers');

    for (final customer in customers) {
      final id = customer['id'];

      if (id == null) continue;

      final document = collection.doc(id.toString());

      batch.set(document, {
        'id': id,
        'name': customer['name'],
        'phone': customer['phone'],
        'address': customer['address'],
        'dailyMilk': customer['dailyMilk'],
        'pricePerLiter': customer['pricePerLiter'],
        'customerType': customer['customerType'],
        'isActive': customer['isActive'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  // ===========================================================
  // MILK ENTRIES
  // ===========================================================

  Future<void> _syncMilkEntries(String uid) async {
    final db = await _database.database;

    final entries = await db.query('milk_entry');

    final batch = _firestore.batch();

    final collection = _firestore
        .collection('users')
        .doc(uid)
        .collection('milk_entries');

    for (final entry in entries) {
      final id = entry['id'];

      if (id == null) continue;

      batch.set(collection.doc(id.toString()), {
        'id': id,
        'date': entry['date'],
        'totalProduction': entry['totalProduction'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  // ===========================================================
  // MILK DELIVERIES
  // ===========================================================

  Future<void> _syncMilkDeliveries(String uid) async {
    final db = await _database.database;

    final deliveries = await db.query('milk_delivery');

    final batch = _firestore.batch();

    final collection = _firestore
        .collection('users')
        .doc(uid)
        .collection('milk_deliveries');

    for (final delivery in deliveries) {
      final id = delivery['id'];

      if (id == null) continue;

      batch.set(collection.doc(id.toString()), {
        'id': id,
        'milkEntryId': delivery['milkEntryId'],
        'customerId': delivery['customerId'],
        'deliveredMilk': delivery['deliveredMilk'],
        'pricePerLiter': delivery['pricePerLiter'],
        'bought': delivery['bought'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }
}
