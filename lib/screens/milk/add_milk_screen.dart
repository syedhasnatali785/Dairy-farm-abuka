import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/customer.dart';
import '../../models/milk_entry.dart';
import '../../providers/customer_provider.dart';
import '../../providers/milk_provider.dart';
import '../../providers/owner_provider.dart';

class AddMilkScreen extends ConsumerStatefulWidget {
  const AddMilkScreen({super.key});

  @override
  ConsumerState<AddMilkScreen> createState() => _AddMilkScreenState();
}

class _AddMilkScreenState extends ConsumerState<AddMilkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productionController = TextEditingController();
  final Set<int> _selectedCustomerIds = {};
  final Map<int, double> _customerAmounts = {};

  bool _isSaving = false;
  bool _productionTouched = false;
  bool _boughtMode = true;

  double _productionValue() =>
      double.tryParse(_productionController.text.trim()) ?? 0;

  void _applyProductionValue(double value) {
    final normalized = value < 0 ? 0 : value;
    _productionController.text = normalized.toStringAsFixed(1);
    _productionController.selection = TextSelection.collapsed(
      offset: _productionController.text.length,
    );
    _productionTouched = true;
  }

  void _adjustProduction(double delta) {
    _applyProductionValue(_productionValue() + delta);
  }

  Future<void> _updateOwnerPrediction(double value) async {
    final owner = ref.read(ownerProvider).valueOrNull;
    if (owner == null) return;

    final nextOwner = owner.copyWith(prediction: value < 0 ? 0 : value);
    await ref.read(ownerProvider.notifier).updateOwner(nextOwner);

    if (_productionController.text.trim().isEmpty) {
      _applyProductionValue(nextOwner.prediction);
    }
  }

  void _toggleCustomer(int customerId) {
    setState(() {
      if (_selectedCustomerIds.contains(customerId)) {
        _selectedCustomerIds.remove(customerId);
        _customerAmounts.remove(customerId);
      } else {
        _selectedCustomerIds.add(customerId);
        final customer = ref
            .read(customerProvider)
            .valueOrNull
            ?.firstWhere(
              (c) => c.id == customerId,
              orElse: () => Customer(
                name: '',
                phone: '',
                address: '',
                dailyMilk: 0,
                pricePerLiter: 0,
                customerType: 'Daily',
              ),
            );
        _customerAmounts[customerId] = customer?.dailyMilk ?? 0;
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
      for (final customer in customers) {
        if (customer.id != null) {
          _customerAmounts[customer.id!] = customer.dailyMilk;
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedCustomerIds.clear();
      _customerAmounts.clear();
    });
  }

  void _adjustCustomerAmount(int customerId, double delta) {
    setState(() {
      final current = _customerAmounts[customerId] ?? 0.0;
      final next = (current + delta) < 0 ? 0.0 : current + delta;
      _customerAmounts[customerId] = double.parse(next.toStringAsFixed(1));
    });
  }

  Future<void> _saveMilkEntry(List<Customer> customers) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (customers.isEmpty) {
      _showMessage('No active customers available.');
      return;
    }

    final totalProduction = double.tryParse(_productionController.text.trim());
    if (totalProduction == null || totalProduction <= 0) {
      _showMessage('Enter a valid production amount.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final today = _dateOnly(DateTime.now());
      final existingEntry = await ref
          .read(milkRepositoryProvider)
          .local
          .getEntryByDate(today);
      if (existingEntry != null) {
        _showMessage('Milk entry for today already exists.');
        return;
      }

      final selectedCustomers = <int, double>{
        for (final customer in customers)
          if (customer.id != null)
            customer.id!: _customerAmounts[customer.id!] ?? customer.dailyMilk,
      };

      await ref
          .read(milkRepositoryProvider)
          .saveDay(
            entry: MilkEntry(date: today, totalProduction: totalProduction),
            customers: customers,
            selectedCustomers: selectedCustomers,
          );

      if (!mounted) return;
      _showMessage('Today\'s milk entry saved successfully.');
      context.pop(true);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to save milk entry. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
  void dispose() {
    _productionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerProvider);
    final ownerAsync = ref.watch(ownerProvider);
    final theme = Theme.of(context);

    final owner = ownerAsync.valueOrNull;
    if (!_productionTouched &&
        _productionController.text.trim().isEmpty &&
        owner != null &&
        owner.prediction > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _productionController.text = owner.prediction.toStringAsFixed(1);
        _productionController.selection = TextSelection.collapsed(
          offset: _productionController.text.length,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Milk')),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Unable to load customers.')),
        data: (customers) {
          if (customers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline, size: 64),
                    const SizedBox(height: 16),
                    const Text('No active customers'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.push('/home/customers/add'),
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Add Customer'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Date'),
                    subtitle: Text(_dateOnly(DateTime.now())),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Total Production',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ownerAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (currentOwner) {
                    final prediction = currentOwner?.prediction ?? 0.0;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () async =>
                                  _updateOwnerPrediction(prediction - 1),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Predicted: ${prediction.toStringAsFixed(1)} L',
                                  style: theme.textTheme.titleSmall,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () async =>
                                  _updateOwnerPrediction(prediction + 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: _isSaving ? null : () => _adjustProduction(-1),
                      icon: const Icon(Icons.remove),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _productionController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => _productionTouched = true,
                        decoration: const InputDecoration(
                          labelText: 'Total Milk Production',
                          hintText: 'e.g. 150',
                          suffixText: 'L',
                          prefixIcon: Icon(Icons.water_drop_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Enter total production';
                          final amount = double.tryParse(value.trim());
                          if (amount == null || amount <= 0)
                            return 'Enter a valid quantity';
                          return null;
                        },
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: _isSaving ? null : () => _adjustProduction(1),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Delivery Mode',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  selected: {_boughtMode},
                  onSelectionChanged: _isSaving
                      ? null
                      : (selection) => setState(() {
                          _boughtMode = selection.first;
                          _selectedCustomerIds.clear();
                        }),
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Bought'),
                      icon: Icon(Icons.check_circle_outline),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Not Bought'),
                      icon: Icon(Icons.cancel_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _boughtMode
                            ? 'Customers Who Bought'
                            : 'Customers Who Did Not Buy',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text('${_selectedCustomerIds.length}/${customers.length}'),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (
                        int index = 0;
                        index < customers.length;
                        index++
                      ) ...[
                        CheckboxListTile(
                          value: _selectedCustomerIds.contains(
                            customers[index].id,
                          ),
                          onChanged: _isSaving
                              ? null
                              : (_) {
                                  final id = customers[index].id;
                                  if (id != null) _toggleCustomer(id);
                                },
                          title: Text(customers[index].name),
                          subtitle: Text(
                            '${customers[index].dailyMilk.toStringAsFixed(1)} L • ${customers[index].pricePerLiter.toStringAsFixed(0)}/L',
                          ),
                          secondary: SizedBox(
                            width: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed:
                                      _isSaving || customers[index].id == null
                                      ? null
                                      : () => _adjustCustomerAmount(
                                          customers[index].id!,
                                          -0.5,
                                        ),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '${(_customerAmounts[customers[index].id!] ?? customers[index].dailyMilk).toStringAsFixed(1)} L',
                                  style: theme.textTheme.bodySmall,
                                ),
                                IconButton(
                                  onPressed:
                                      _isSaving || customers[index].id == null
                                      ? null
                                      : () => _adjustCustomerAmount(
                                          customers[index].id!,
                                          0.5,
                                        ),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (index != customers.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
              ],
            ),
          );
        },
      ),
    );
  }
}
