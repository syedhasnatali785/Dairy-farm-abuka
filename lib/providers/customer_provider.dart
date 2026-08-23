import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import '../repositories/customer_repository.dart';
import 'sync_provider.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

final customerProvider =
    AsyncNotifierProvider<CustomerNotifier, List<Customer>>(
      CustomerNotifier.new,
    );

class CustomerNotifier extends AsyncNotifier<List<Customer>> {
  late final CustomerRepository _repository;

  @override
  Future<List<Customer>> build() async {
    _repository = ref.read(customerRepositoryProvider);

    // SQLite → UI immediately
    final customers = await _repository.getCustomers();

    // Firebase sync background mein
    _syncInBackground();

    return customers;
  }

  // =========================================================
  // BACKGROUND SYNC
  // =========================================================

  Future<void> _syncInBackground() async {
    try {
      await ref.read(syncProvider.notifier).sync();

      // Firebase → SQLite ke baad
      // latest local data reload
      final customers = await _repository.getCustomers();

      state = AsyncData(customers);
    } catch (_) {
      // Offline ho to SQLite data continue karega.
    }
  }

  // =========================================================
  // REFRESH
  // =========================================================

  Future<void> refresh() async {
    try {
      final customers = await _repository.getCustomers();

      state = AsyncData(customers);

      _syncInBackground();
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  // =========================================================
  // ADD CUSTOMER
  // =========================================================

  Future<bool> addCustomer(Customer customer) async {
    try {
      await _repository.addCustomer(customer);

      final customers = await _repository.getCustomers();

      state = AsyncData(customers);

      _syncInBackground();

      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);

      return false;
    }
  }

  // =========================================================
  // UPDATE CUSTOMER
  // =========================================================

  Future<bool> updateCustomer(Customer customer) async {
    try {
      await _repository.updateCustomer(customer);

      final customers = await _repository.getCustomers();

      state = AsyncData(customers);

      _syncInBackground();

      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);

      return false;
    }
  }

  // =========================================================
  // DEACTIVATE
  // =========================================================

  Future<bool> deleteCustomer(int id) async {
    try {
      await _repository.deleteCustomer(id);

      final customers = await _repository.getCustomers();

      state = AsyncData(customers);

      _syncInBackground();

      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);

      return false;
    }
  }

  // =========================================================
  // ACTIVATE / DEACTIVATE
  // =========================================================

  Future<bool> setActive({required int id, required bool isActive}) async {
    try {
      await _repository.setActive(id, isActive);

      final customers = await _repository.getCustomers();

      state = AsyncData(customers);

      _syncInBackground();

      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);

      return false;
    }
  }

  // =========================================================
  // RESTORE
  // =========================================================

  Future<bool> restoreCustomer(int id) async {
    try {
      await _repository.restoreCustomer(id);

      final customers = await _repository.getCustomers();

      state = AsyncData(customers);

      _syncInBackground();

      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);

      return false;
    }
  }

  // =========================================================
  // SEARCH
  // =========================================================

  Future<List<Customer>> search(String keyword) async {
    return _repository.searchCustomers(keyword);
  }
}
