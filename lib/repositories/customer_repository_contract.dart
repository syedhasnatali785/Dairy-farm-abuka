import '../models/customer.dart';

enum CustomerDataSource { sqlite, firebase }

abstract class BaseCustomerRepository {
  Future<List<Customer>> getCustomers();

  Future<List<Customer>> searchCustomers(String keyword);

  Future<dynamic> addCustomer(Customer customer);

  Future<void> updateCustomer(Customer customer, {Object? id});

  Future<void> deleteCustomer(Object id);

  Future<void> setActive(Object id, bool isActive);

  Future<Customer?> getCustomerById(Object id);
}
