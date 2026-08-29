import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dairyfarmabuka/models/customer.dart';
import 'package:dairyfarmabuka/repositories/customer_repository_contract.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreCustomerRepository implements BaseCustomerRepository {
  FirestoreCustomerRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

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

  @override
  Future<List<Customer>> getCustomers() async {
    final snapshot = await _customers.orderBy('name').get();
    return snapshot.docs.map((doc) {
      return _fromFirestore(doc.id, doc.data());
    }).toList();
  }

  Future<List<Customer>> getActiveCustomers() async {
    final snapshot = await _customers
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
    return snapshot.docs.map((doc) {
      return _fromFirestore(doc.id, doc.data());
    }).toList();
  }

  @override
  Future<Customer?> getCustomerById(Object id) async {
    final docId = _requireStringId(id);
    final doc = await _customers.doc(docId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return _fromFirestore(doc.id, doc.data()!);
  }

  @override
  Future<String> addCustomer(Customer customer) async {
    final doc = await _customers.add(_toFirestore(customer));
    return doc.id;
  }

  @override
  Future<void> updateCustomer(Customer customer, {Object? id}) async {
    final docId = _requireStringId(id ?? customer.firebaseId);
    await _customers.doc(docId).update(_toFirestore(customer));
  }

  @override
  Future<void> deleteCustomer(Object id) async {
    await _customers.doc(_requireStringId(id)).delete();
  }

  @override
  Future<void> setActive(Object id, bool isActive) async {
    await _customers.doc(_requireStringId(id)).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<Customer>> searchCustomers(String keyword) async {
    final customers = await getCustomers();
    final query = keyword.trim().toLowerCase();
    if (query.isEmpty) {
      return customers;
    }
    return customers.where((customer) {
      final phone = customer.phone.toLowerCase();
      final name = customer.name.toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  String _requireStringId(Object? id) {
    if (id == null) {
      throw StateError('Firestore customer id is required.');
    }
    final value = id.toString();
    if (value.isEmpty) {
      throw StateError('Firestore customer id cannot be empty.');
    }
    return value;
  }
}

Customer _fromFirestore(String id, Map<String, dynamic> data) {
  return Customer(
    id: int.tryParse(id) ?? 0,
    firebaseId: id,
    name: data['name'] as String? ?? '',
    phone: data['phone'] as String? ?? '',
    address: data['address'] as String? ?? '',
    dailyMilk: _toDouble(data['dailyMilk']),
    pricePerLiter: _toDouble(data['pricePerLiter']),
    customerType: data['customerType'] as String? ?? 'Daily',
    isActive: data['isActive'] as bool? ?? true,
  );
}

Map<String, dynamic> _toFirestore(Customer customer) {
  return {
    'name': customer.name,
    'phone': customer.phone,
    'address': customer.address,
    'dailyMilk': customer.dailyMilk,
    'pricePerLiter': customer.pricePerLiter,
    'customerType': customer.customerType,
    'isActive': customer.isActive,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
