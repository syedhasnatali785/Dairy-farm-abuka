import 'package:dairyfarmabuka/models/customer.dart';
import 'package:dairyfarmabuka/repositories/customer_repository.dart';
import 'package:dairyfarmabuka/repositories/customer_repository_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('customer repository contract', () {
    test('sqlite repository implements the shared customer contract', () {
      final sqlite = CustomerRepository();

      expect(sqlite, isA<BaseCustomerRepository>());
    });

    test('customer model can represent both local and remote identities', () {
      final customer = Customer(
        id: 42,
        firebaseId: 'firebase-42',
        name: 'Ali',
        phone: '03001234567',
        address: 'Lahore',
        dailyMilk: 55,
        pricePerLiter: 120,
        customerType: 'Daily',
        isActive: true,
      );

      expect(customer.id, 42);
      expect(customer.firebaseId, 'firebase-42');
      expect(customer.toMap()['id'], 42);
      expect(customer.toFirestore()['name'], 'Ali');
    });
  });
}
