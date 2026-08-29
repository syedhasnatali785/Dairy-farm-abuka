import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/owner.dart';
import '../repositories/owner_repository.dart';

class UnifiedOwnerRepository {
  final OwnerRepository local = OwnerRepository();
  final FirebaseFirestore remote = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> saveOwner(Owner owner) async {
    await Future.wait([local.saveOwner(owner), _saveRemote(owner)]);
  }

  Future<void> updateOwner(Owner owner) async {
    await Future.wait([local.updateOwner(owner), _saveRemote(owner)]);
  }

  Future<Owner?> getOwner() async {
    return await local.getOwner();
  }

  Future<void> deleteOwner() async {
    await Future.wait([local.deleteOwner(), _deleteRemote()]);
  }

  Future<void> _saveRemote(Owner owner) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    await remote
        .collection('owners')
        .doc(uid)
        .set(owner.toMap(), SetOptions(merge: true));
  }

  Future<void> _deleteRemote() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    await remote.collection('owners').doc(uid).delete();
  }
}

final ownerRepositoryProvider = Provider<UnifiedOwnerRepository>((ref) {
  return UnifiedOwnerRepository();
});

final ownerProvider = AsyncNotifierProvider<OwnerNotifier, Owner?>(
  OwnerNotifier.new,
);

class OwnerNotifier extends AsyncNotifier<Owner?> {
  UnifiedOwnerRepository get _repository => ref.read(ownerRepositoryProvider);

  @override
  Future<Owner?> build() async {
    return _repository.getOwner();
  }

  Future<void> loadOwner() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.getOwner);
  }

  Future<void> saveOwner(Owner owner) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.saveOwner(owner);
      return _repository.getOwner();
    });
  }

  Future<void> updateOwner(Owner owner) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.updateOwner(owner);
      return _repository.getOwner();
    });
  }

  Future<void> deleteOwner() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteOwner();
      return null;
    });
  }
}
