import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dairyfarmabuka/models/milk_delivery.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreMilkRepository {
  FirestoreMilkRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _milkEntries {
    return _firestore.collection('owners').doc(_uid).collection('milk_entries');
  }

  CollectionReference<Map<String, dynamic>> get _milkDeliveries {
    return _firestore
        .collection('owners')
        .doc(_uid)
        .collection('milk_deliveries');
  }

  Future<String> saveDay({
    required DateTime date,
    required double totalProduction,
    required List<MilkDelivery> deliveries,
  }) async {
    if (totalProduction < 0) {
      throw Exception('Total production cannot be negative.');
    }
    final dateKey = _dateKey(date);
    final existing = await _milkEntries
        .where('dateKey', isEqualTo: dateKey)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Milk entry for this date already exists.');
    }
    final entryRef = _milkEntries.doc();
    final batch = _firestore.batch();
    batch.set(entryRef, {
      'date': Timestamp.fromDate(date),
      'dateKey': dateKey,
      'totalProduction': totalProduction,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    for (final delivery in deliveries) {
      final deliveryRef = _milkDeliveries.doc();
      batch.set(deliveryRef, {
        'milkEntryId': entryRef.id,
        'customerId': delivery.customerId,
        'deliveredMilk': delivery.deliveredMilk,
        'pricePerLiter': delivery.pricePerLiter,
        'bought': delivery.bought,
        'dateKey': dateKey,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return entryRef.id;
  }

  Future<Map<String, dynamic>?> getDay(DateTime date) async {
    final dateKey = _dateKey(date);
    final snapshot = await _milkEntries
        .where('dateKey', isEqualTo: dateKey)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    final doc = snapshot.docs.first;
    return {'id': doc.id, ...doc.data()};
  }

  Future<List<Map<String, dynamic>>> getMilkEntries() async {
    final snapshot = await _milkEntries.orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getDeliveries(String milkEntryId) async {
    final snapshot = await _milkDeliveries
        .where('milkEntryId', isEqualTo: milkEntryId)
        .get();

    return snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
  }

  Future<void> deleteDay(String milkEntryId) async {
    final deliveries = await _milkDeliveries
        .where('milkEntryId', isEqualTo: milkEntryId)
        .get();

    final batch = _firestore.batch();
    for (final doc in deliveries.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_milkEntries.doc(milkEntryId));
    await batch.commit();
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
