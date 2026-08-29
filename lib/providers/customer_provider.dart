import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import '../repositories/customer_repository.dart';
import '../repositories/customer_repository_contract.dart';
import '../repositories/firestore_customer_repository.dart';

class UnifiedCustomerRepository implements BaseCustomerRepository {
  final CustomerRepository local = CustomerRepository();
  final FirestoreCustomerRepository remote = FirestoreCustomerRepository();

  @override
  Future<dynamic> addCustomer(Customer customer) async {
    await Future.wait([local.addCustomer(customer), _remoteAdd(customer)]);
    return true;
  }

  @override
  Future<List<Customer>> getCustomers() async {
    try {
      return await local.getCustomers();
    } catch (_) {
      return await remote.getCustomers();
    }
  }

  @override
  Future<void> updateCustomer(Customer customer, {Object? id}) async {
    await Future.wait([
      local.updateCustomer(
        customer,
        id: id ?? customer.id ?? customer.firebaseId,
      ),
      _remoteUpdate(customer, id ?? customer.firebaseId ?? customer.id),
    ]);
  }

  @override
  Future<void> deleteCustomer(Object id) async {
    await Future.wait([local.deleteCustomer(id), _remoteDelete(id)]);
  }

  @override
  Future<void> setActive(Object id, bool isActive) async {
    await Future.wait([
      local.setActive(id, isActive),
      _remoteSetActive(id, isActive),
    ]);
  }

  @override
  Future<Customer?> getCustomerById(Object id) async {
    return await local.getCustomerById(id) ?? await remote.getCustomerById(id);
  }

  @override
  Future<List<Customer>> searchCustomers(String keyword) async {
    return await local.searchCustomers(keyword);
  }

  Future<void> _remoteAdd(Customer customer) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    await remote.addCustomer(customer);
  }

  Future<void> _remoteUpdate(Customer customer, Object? id) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    if (id == null) return;
    await remote.updateCustomer(customer, id: id);
  }

  Future<void> _remoteDelete(Object id) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    await remote.deleteCustomer(id);
  }

  Future<void> _remoteSetActive(Object id, bool isActive) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    await remote.setActive(id, isActive);
  }
}

final customerRepositoryProvider = Provider<BaseCustomerRepository>((ref) {
  return UnifiedCustomerRepository();
});

final customerProvider =
    AsyncNotifierProvider<CustomerNotifier, List<Customer>>(
      CustomerNotifier.new,
    );

class CustomerNotifier extends AsyncNotifier<List<Customer>> {
  BaseCustomerRepository get _repository =>
      ref.read(customerRepositoryProvider);

  @override
  Future<List<Customer>> build() async {
    return _repository.getCustomers();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.getCustomers);
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
        id: customer.id ?? customer.firebaseId,
      );
      await refresh();
      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  Future<bool> setActive(Object id, bool isActive) async {
    try {
      await _repository.setActive(id, isActive);
      await refresh();
      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  Future<bool> deleteCustomer(Object id) async {
    try {
      await _repository.deleteCustomer(id);
      await refresh();
      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  Future<bool> restoreCustomer(Object id) async {
    try {
      if (id is int) {
        await (ref.read(customerRepositoryProvider)
                as UnifiedCustomerRepository)
            .local
            .restoreCustomer(id);
      } else {
        await _repository.setActive(id, true);
      }
      await refresh();
      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  Future<Customer?> getCustomerById(Object id) async {
    return _repository.getCustomerById(id);
  }

  Future<List<Customer>> search(String keyword) async {
    if (keyword.trim().isEmpty) {
      return state.valueOrNull ?? [];
    }
    return _repository.searchCustomers(keyword.trim());
  }
}
