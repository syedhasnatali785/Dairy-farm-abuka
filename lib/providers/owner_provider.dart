import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
final ownerProvider = AsyncNotifierProvider<OwnerNotifier, OwnerProfile?>(
  OwnerNotifier.new,
);

class OwnerProfile {
  final String uid;
  final String name;
  final String farmName;
  final String phone;
  final String address;
  final double prediction;
  final bool onboardingCompleted;
  const OwnerProfile({
    required this.uid,
    this.name = '',
    this.farmName = '',
    this.phone = '',
    this.address = '',
    this.prediction = 0,
    this.onboardingCompleted = false,
  });
  factory OwnerProfile.fromMap(String uid, Map<String, dynamic> map) {
    return OwnerProfile(
      uid: uid,
      name: map['name'] ?? '',
      farmName: map['farmName'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      prediction: (map['prediction'] ?? 0).toDouble(),
      onboardingCompleted: map['onboardingCompleted'] ?? false,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'farmName': farmName,
      'phone': phone,
      'address': address,
      'prediction': prediction,
      'onboardingCompleted': onboardingCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class OwnerNotifier extends AsyncNotifier<OwnerProfile?> {
  FirebaseFirestore get _firestore => ref.read(firestoreProvider);
  FirebaseAuth get _auth => FirebaseAuth.instance;
  @override
  Future<OwnerProfile?> build() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    return getOwner(user.uid);
  }

  Future<OwnerProfile?> getOwner(String uid) async {
    final doc = await _firestore.collection('owners').doc(uid).get();
    if (!doc.exists) {
      return null;
    }
    return OwnerProfile.fromMap(uid, doc.data()!);
  }

  Future<bool> saveOwner({
    required String name,
    required String farmName,
    required String phone,
    required String address,
    required double prediction,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }
    state = const AsyncLoading();
    try {
      final owner = OwnerProfile(
        uid: user.uid,
        name: name.trim(),
        farmName: farmName.trim(),
        phone: phone.trim(),
        address: address.trim(),
        prediction: prediction,
        onboardingCompleted: true,
      );
      await _firestore
          .collection('owners')
          .doc(user.uid)
          .set(owner.toMap(), SetOptions(merge: true));
      state = AsyncData(owner);
      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }
      return getOwner(user.uid);
    });
  }
}
