import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/owner.dart';
import '../repositories/owner_repository.dart';

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  return OwnerRepository();
});

final ownerProvider = AsyncNotifierProvider<OwnerNotifier, Owner?>(
  OwnerNotifier.new,
);

class OwnerNotifier extends AsyncNotifier<Owner?> {
  OwnerRepository get _repository => ref.read(ownerRepositoryProvider);

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
