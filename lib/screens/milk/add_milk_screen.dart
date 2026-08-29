import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/customer.dart';
import '../../models/milk_entry.dart';
import '../../providers/customer_provider.dart';
import '../../providers/owner_provider.dart';
import '../../providers/milk_provider.dart';
import '../../repositories/milk_repository.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Use shared provider from providers/milk_provider.dart

class AddMilkScreen extends ConsumerStatefulWidget {
  const AddMilkScreen({super.key});

  @override
  ConsumerState<AddMilkScreen> createState() => _AddMilkScreenState();
}

class _AddMilkScreenState extends ConsumerState<AddMilkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productionController = TextEditingController();

  bool _isSaving = false;
  bool _productionTouched = false;

  /// true  = selected customers BOUGHT
  /// false = selected customers DID NOT BUY
  bool _boughtMode = true;

  final Set<int> _selectedCustomerIds = {};
  final Map<int, double> _customerAmounts = {};

  bool _notificationsInitialized = false;

  double _productionValue() {
    final value = double.tryParse(_productionController.text.trim());
    return value ?? 0;
  }

  void _applyProductionValue(double value) {
    final normalized = value < 0 ? 0 : value;
    _productionController.text = normalized.toStringAsFixed(1);
    _productionController.selection = TextSelection.collapsed(
      offset: _productionController.text.length,
    );
    _productionTouched = true;
  }

  // ===============================================================
  // NOTIFICATIONS
  // ===============================================================

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> _initNotifications() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await _notificationsPlugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    // Request runtime permissions (Android 13+ / iOS) — without this,
    // zonedSchedule can silently fail to actually notify the user.
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _scheduleDailyReminder({int hour = 8, int minute = 0}) async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    final exists = pending.any((p) => p.id == 0);

    if (exists) {
      await _notificationsPlugin.cancel(id: 0);
      if (mounted) _showMessage('Daily reminder cancelled');
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'milk_reminder',
      'Milk Reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id: 0,
      title: 'Milk Reminder',
      body: 'Don\'t forget to record today\'s milk.',
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    if (mounted) {
      _showMessage(
        'Daily reminder scheduled at '
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      );
    }
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

  @override
  void initState() {
    super.initState();
    // Initialize once, not on every build().
    _initNotifications().then((_) {
      if (mounted) {
        setState(() {
          _notificationsInitialized = true;
        });
      }
    });
  }

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
      _customerAmounts.clear(); // avoid stale amounts leaking across modes
    });
  }

  void _toggleCustomer(int customerId) {
    setState(() {
      if (_selectedCustomerIds.contains(customerId)) {
        _selectedCustomerIds.remove(customerId);
        _customerAmounts.remove(customerId);
      } else {
        _selectedCustomerIds.add(customerId);
        // initialize amount for this customer from current provider value
        final customers = ref.read(customerProvider).valueOrNull;
        Customer? foundCustomer;
        if (customers != null) {
          for (final c in customers) {
            if (c.id == customerId) {
              foundCustomer = c;
              break;
            }
          }
        }
        if (foundCustomer != null) {
          _customerAmounts[customerId] = foundCustomer.dailyMilk;
        } else {
          _customerAmounts[customerId] = 0.0;
        }
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
      for (final c in customers) {
        if (c.id != null) {
          _customerAmounts[c.id!] = c.dailyMilk;
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

      // Build amounts based on the actual selection + mode, instead of
      // ignoring them. In "Bought" mode, selected customers get their
      // entered amount and everyone else is recorded as 0 (didn't buy).
      // In "Not Bought" mode it's inverted: selected customers get 0,
      // everyone else gets their entered/default amount.
      final selectedCustomers = <int, double>{
        for (final customer in customers)
          if (customer.id != null) customer.id!: _resolvedAmountFor(customer),
      };

      await ref
          .read(milkRepositoryProvider)
          .saveDay(
            entry: entry,
            customers: customers,
            selectedCustomers: selectedCustomers,
          );

      if (!mounted) return;

      _showMessage("Today's milk entry saved successfully.");

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

  /// Resolves the amount to save for a given customer based on the
  /// current delivery mode and whether they're selected.
  double _resolvedAmountFor(Customer customer) {
    final id = customer.id;
    if (id == null) return 0.0;

    final isSelected = _selectedCustomerIds.contains(id);
    final didBuy = _boughtMode ? isSelected : !isSelected;

    if (!didBuy) return 0.0;

    return _customerAmounts[id] ?? customer.dailyMilk;
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
      appBar: AppBar(
        title: const Text('Add Milk'),
        actions: [
          IconButton(
            tooltip: 'Toggle daily reminder',
            onPressed: _notificationsInitialized
                ? () async {
                    await _scheduleDailyReminder();
                  }
                : null,
            icon: const Icon(Icons.alarm),
          ),
        ],
      ),
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
                              onPressed: () async {
                                await _updateOwnerPrediction(prediction - 1);
                              },
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
                              onPressed: () async {
                                await _updateOwnerPrediction(prediction + 1);
                              },
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
                        onChanged: (_) {
                          _productionTouched = true;
                        },
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
                    ),
                    IconButton.filledTonal(
                      onPressed: _isSaving ? null : () => _adjustProduction(1),
                      icon: const Icon(Icons.add),
                    ),
                  ],
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
                    IconButton(
                      onPressed: _isSaving ? null : () => _clearSelection(),
                      tooltip: 'Remove all selected customers',
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${_selectedCustomerIds.length}/${customers.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: _isSaving ? null : () => _selectAll(customers),
                      tooltip: 'Select all customers',
                      icon: const Icon(Icons.add_circle_outline),
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
                          amount: customers[index].id != null
                              ? _customerAmounts[customers[index].id!] ??
                                    customers[index].dailyMilk
                              : customers[index].dailyMilk,
                          onIncrease: (id) => _adjustCustomerAmount(id, 0.5),
                          onDecrease: (id) => _adjustCustomerAmount(id, -0.5),
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
    required this.amount,
    required this.onIncrease,
    required this.onDecrease,
  });

  final Customer customer;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final double amount;
  final void Function(int) onIncrease;
  final void Function(int) onDecrease;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: selected,
      onChanged: enabled ? (_) => onTap() : null,
      title: Text(customer.name),
      subtitle: Text('${customer.dailyMilk} L • ${customer.pricePerLiter}/L'),
      secondary: SizedBox(
        width: 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              child: Text(
                customer.name.trim().isEmpty
                    ? '?'
                    : customer.name.trim().substring(0, 1).toUpperCase(),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  iconSize: 20,
                  onPressed: enabled && customer.id != null
                      ? () => onDecrease(customer.id!)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Flexible(
                  child: Text(
                    '${amount.toStringAsFixed(1)} L',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  iconSize: 20,
                  onPressed: enabled && customer.id != null
                      ? () => onIncrease(customer.id!)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
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
