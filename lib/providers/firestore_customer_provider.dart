import 'package:dairyfarmabuka/models/customer.dart';
import 'package:dairyfarmabuka/repositories/firestore_customer_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreCustomerRepositoryProvider =
    Provider<FirestoreCustomerRepository>(
      (ref) => FirestoreCustomerRepository(),
    );
final firestoreCustomerProvider =
    AsyncNotifierProvider<FirestoreCustomerNotifier, List<Customer>>(
      FirestoreCustomerNotifier.new,
    );

class FirestoreCustomerNotifier extends AsyncNotifier<List<Customer>> {
  FirestoreCustomerRepository get _repository =>
      ref.read(firestoreCustomerRepositoryProvider);
  @override
  Future<List<Customer>> build() async {
    return _repository.getCustomers();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getCustomers());
  }

  Future<bool> addCustomer(Customer customer) async {
    try {
      await _repository.addCustomer(customer);
      await refresh();
      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  Future<bool> updateCustomer(Customer customer) async {
    try {
      await _repository.updateCustomer(
        customer,
        id: customer.firebaseId ?? customer.id,
      );
      await refresh();
      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      await _repository.deleteCustomer(id);

      await refresh();

      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);

      return false;
    }
  }

  Future<bool> setActive({required String id, required bool isActive}) async {
    try {
      await _repository.setActive(id, isActive);

      await refresh();

      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);

      return false;
    }
  }
}
