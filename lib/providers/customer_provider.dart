import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import '../repositories/customer_repository.dart';
import '../repositories/customer_repository_contract.dart';
import '../repositories/firestore_customer_repository.dart';

final customerDataSourceProvider = StateProvider<CustomerDataSource>(
  (ref) => CustomerDataSource.sqlite,
);

final customerRepositoryProvider = Provider<BaseCustomerRepository>((ref) {
  final dataSource = ref.watch(customerDataSourceProvider);

  switch (dataSource) {
    case CustomerDataSource.sqlite:
      return CustomerRepository();
    case CustomerDataSource.firebase:
      return FirestoreCustomerRepository();
  }
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
        await (ref.read(customerRepositoryProvider) as CustomerRepository)
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
