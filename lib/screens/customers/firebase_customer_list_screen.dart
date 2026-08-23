import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/customer.dart';
import '../../providers/firestore_customer_provider.dart';
import 'add_customer_screen.dart';
import 'edit_customer_screen.dart';

class FirebaseCustomerListScreen extends ConsumerWidget {
  const FirebaseCustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerState = ref.watch(firestoreCustomerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(firestoreCustomerProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
          );

          ref.read(firestoreCustomerProvider.notifier).refresh();
        },
        child: const Icon(Icons.add),
      ),

      body: customerState.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 50),

                  const SizedBox(height: 12),

                  Text(error.toString(), textAlign: TextAlign.center),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () {
                      ref.read(firestoreCustomerProvider.notifier).refresh();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },

        data: (customers) {
          if (customers.isEmpty) {
            return const Center(
              child: Text(
                'No customers yet.\n\n'
                'Tap + to add your first customer.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () {
              return ref.read(firestoreCustomerProvider.notifier).refresh();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: customers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final customer = customers[index];

                return _CustomerCard(
                  customer: customer,

                  onEdit: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditCustomerScreen(customer: customer),
                      ),
                    );

                    ref.read(firestoreCustomerProvider.notifier).refresh();
                  },

                  onDelete: () {
                    _deleteCustomer(context, ref, customer);
                  },

                  onToggleActive: () {
                    _toggleActive(context, ref, customer);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteCustomer(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) async {
    final firebaseId = customer.firebaseId;

    if (firebaseId == null || firebaseId.isEmpty) {
      _showMessage(context, 'Firebase ID is missing.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Customer?'),
          content: Text(
            'Are you sure you want to delete '
            '${customer.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final success = await ref
        .read(firestoreCustomerProvider.notifier)
        .deleteCustomer(firebaseId);

    if (!context.mounted) return;

    _showMessage(
      context,
      success ? 'Customer deleted.' : 'Failed to delete customer.',
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) async {
    final firebaseId = customer.firebaseId;

    if (firebaseId == null || firebaseId.isEmpty) {
      _showMessage(context, 'Firebase ID is missing.');
      return;
    }

    final success = await ref
        .read(firestoreCustomerProvider.notifier)
        .setActive(id: firebaseId, isActive: !customer.isActive);

    if (!context.mounted) return;

    _showMessage(
      context,
      success
          ? customer.isActive
                ? 'Customer deactivated.'
                : 'Customer activated.'
          : 'Failed to update customer.',
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _CustomerCard({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            customer.name.isEmpty ? '?' : customer.name[0].toUpperCase(),
          ),
        ),

        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            Text('${customer.dailyMilk} L/day'),

            Text(
              'Rs. ${customer.pricePerLiter}/L • '
              '${customer.customerType}',
            ),

            Text(
              customer.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: customer.isActive ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        isThreeLine: true,

        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;

              case 'toggle':
                onToggleActive();
                break;

              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit'),
              ),
            ),

            PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                leading: Icon(
                  customer.isActive
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                ),
                title: Text(customer.isActive ? 'Deactivate' : 'Activate'),
              ),
            ),

            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('Delete'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
