import 'package:dairyfarmabuka/models/customer.dart';
import 'package:dairyfarmabuka/providers/customer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _milkController = TextEditingController();
  final _priceController = TextEditingController();

  String _customerType = 'DAILY';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _milkController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final customer = Customer(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      dailyMilk: double.parse(_milkController.text.trim()),
      pricePerLiter: double.parse(_priceController.text.trim()),
      customerType: _customerType,
      isActive: true,
    );

    setState(() {
      _saving = true;
    });

    final success = await ref.read(customerProvider.notifier).addCustomer(customer);

    if (!mounted) return;

    setState(() {
      _saving = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer added successfully.')),
      );

      Navigator.pop(context, true);
    } else {
      final error = ref.read(customerProvider).error;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.toString() ?? 'Failed to add customer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Customer')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter customer name';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _milkController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Daily Milk',
                  hintText: 'e.g. 5',
                  suffixText: 'L',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.water_drop_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter daily milk';
                  }

                  final number = double.tryParse(value.trim());

                  if (number == null || number <= 0) {
                    return 'Enter a valid milk quantity';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Price Per Liter',
                  hintText: 'e.g. 220',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter price per liter';
                  }

                  final number = double.tryParse(value.trim());

                  if (number == null || number <= 0) {
                    return 'Enter a valid price';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _customerType,
                decoration: const InputDecoration(
                  labelText: 'Customer Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                  DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _customerType = value;
                  });
                },
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _saveCustomer,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'SAVE CUSTOMER'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
