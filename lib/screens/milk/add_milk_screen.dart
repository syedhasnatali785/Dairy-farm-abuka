import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/customer.dart';
import '../../models/milk_entry.dart';
import '../../providers/customer_provider.dart';
import '../../repositories/milk_repository.dart';

final milkRepositoryProvider = Provider<MilkRepository>((ref) {
  return MilkRepository();
});

class AddMilkScreen extends ConsumerStatefulWidget {
  const AddMilkScreen({super.key});

  @override
  ConsumerState<AddMilkScreen> createState() => _AddMilkScreenState();
}

class _AddMilkScreenState extends ConsumerState<AddMilkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productionController = TextEditingController();

  bool _isSaving = false;

  /// true  = selected customers BOUGHT
  /// false = selected customers DID NOT BUY
  bool _boughtMode = true;

  final Set<int> _selectedCustomerIds = {};

  @override
  void dispose() {
    _productionController.dispose();
    super.dispose();
  }

  void _changeMode(bool mode) {
    if (_boughtMode == mode) return;

    setState(() {
      _boughtMode = mode;
      _selectedCustomerIds.clear();
    });
  }

  void _toggleCustomer(int customerId) {
    setState(() {
      if (_selectedCustomerIds.contains(customerId)) {
        _selectedCustomerIds.remove(customerId);
      } else {
        _selectedCustomerIds.add(customerId);
      }
    });
  }

  void _selectAll(List<Customer> customers) {
    setState(() {
      _selectedCustomerIds
        ..clear()
        ..addAll(
          customers
              .where((customer) => customer.id != null)
              .map((customer) => customer.id!),
        );
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedCustomerIds.clear();
    });
  }

  Future<void> _saveMilkEntry(List<Customer> customers) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (customers.isEmpty) {
      _showMessage('No active customers available.');
      return;
    }

    final totalProduction = double.tryParse(_productionController.text.trim());

    if (totalProduction == null || totalProduction <= 0) {
      _showMessage('Enter a valid production amount.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final today = _dateOnly(DateTime.now());

      // Prevent duplicate entry for the same day.
      final existingEntry = await ref
          .read(milkRepositoryProvider)
          .getEntryByDate(today);

      if (existingEntry != null) {
        if (!mounted) return;

        _showMessage('Milk entry for today already exists.');

        return;
      }

      final entry = MilkEntry(date: today, totalProduction: totalProduction);

      final selectedCustomers = <int, bool>{
        for (final customer in customers)
          if (customer.id != null)
            customer.id!: _selectedCustomerIds.contains(customer.id!),
      };

      await ref
          .read(milkRepositoryProvider)
          .saveDay(
            entry: entry,
            customers: customers,
            selectedCustomers: selectedCustomers,
            boughtMode: _boughtMode,
          );

      if (!mounted) return;

      _showMessage('Today\'s milk entry saved successfully.');

      context.pop(true);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to save milk entry. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _dateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Milk')),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorView(
          onRetry: () {
            ref.read(customerProvider.notifier).refresh();
          },
        ),
        data: (customers) {
          if (customers.isEmpty) {
            return _EmptyCustomersView(
              onAddCustomer: () {
                context.push('/home/customers/add');
              },
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // =================================================
                // DATE
                // =================================================
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Date'),
                    subtitle: Text(_formattedToday()),
                  ),
                ),

                const SizedBox(height: 16),

                // =================================================
                // TOTAL PRODUCTION
                // =================================================
                Text(
                  'Total Production',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _productionController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Total Milk Production',
                    hintText: 'e.g. 150',
                    suffixText: 'L',
                    prefixIcon: Icon(Icons.water_drop_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter total production';
                    }

                    final amount = double.tryParse(value.trim());

                    if (amount == null || amount <= 0) {
                      return 'Enter a valid quantity';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // =================================================
                // MODE
                // =================================================
                Text(
                  'Delivery Mode',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Bought'),
                      icon: Icon(Icons.check_circle_outline),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Not Bought'),
                      icon: Icon(Icons.cancel_outlined),
                    ),
                  ],
                  selected: {_boughtMode},
                  onSelectionChanged: _isSaving
                      ? null
                      : (selection) {
                          _changeMode(selection.first);
                        },
                ),

                const SizedBox(height: 8),

                Text(
                  _boughtMode
                      ? 'Select customers who bought milk. Unselected customers will be marked Not Bought.'
                      : 'Select customers who did not buy milk. Unselected customers will be marked Bought.',
                  style: theme.textTheme.bodySmall,
                ),

                const SizedBox(height: 16),

                // =================================================
                // SELECTION ACTIONS
                // =================================================
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _selectAll(customers),
                        icon: const Icon(Icons.select_all),
                        label: const Text('Select All'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _clearSelection,
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Clear'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // =================================================
                // CUSTOMER COUNT
                // =================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _boughtMode
                          ? 'Customers Who Bought'
                          : 'Customers Who Did Not Buy',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_selectedCustomerIds.length}/${customers.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // =================================================
                // CUSTOMERS
                // =================================================
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (
                        int index = 0;
                        index < customers.length;
                        index++
                      ) ...[
                        _CustomerTile(
                          customer: customers[index],
                          selected: _selectedCustomerIds.contains(
                            customers[index].id,
                          ),
                          enabled: !_isSaving,
                          onTap: () {
                            final id = customers[index].id;

                            if (id != null) {
                              _toggleCustomer(id);
                            }
                          },
                        ),
                        if (index != customers.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // =================================================
                // SAVE
                // =================================================
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () => _saveMilkEntry(customers),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Saving...' : 'Save Milk Entry'),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formattedToday() {
    final now = DateTime.now();

    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');

    return '$day/$month/${now.year}';
  }
}

// ===============================================================
// CUSTOMER TILE
// ===============================================================

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.customer,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Customer customer;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: selected,
      onChanged: enabled ? (_) => onTap() : null,
      title: Text(customer.name),
      subtitle: Text('${customer.dailyMilk} L • ${customer.pricePerLiter}/L'),
      secondary: CircleAvatar(
        child: Text(
          customer.name.trim().isEmpty
              ? '?'
              : customer.name.trim().substring(0, 1).toUpperCase(),
        ),
      ),
    );
  }
}

// ===============================================================
// ERROR VIEW
// ===============================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52),
            const SizedBox(height: 12),
            const Text('Unable to load customers.'),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ===============================================================
// EMPTY CUSTOMERS VIEW
// ===============================================================

class _EmptyCustomersView extends StatelessWidget {
  const _EmptyCustomersView({required this.onAddCustomer});

  final VoidCallback onAddCustomer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              'No active customers',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add customers before recording milk deliveries.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddCustomer,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add Customer'),
            ),
          ],
        ),
      ),
    );
  }
}
