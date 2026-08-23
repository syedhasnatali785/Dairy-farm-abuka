import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ownerNameController = TextEditingController();

  final _farmNameController = TextEditingController();

  final _phoneController = TextEditingController();

  final _addressController = TextEditingController();

  final _predictionController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _ownerNameController.dispose();
    _farmNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _predictionController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final prediction = double.parse(_predictionController.text.trim());

      final prefs = await SharedPreferences.getInstance();

      // ------------------------------------------------------
      // Local onboarding data
      // ------------------------------------------------------

      await prefs.setString('owner_name', _ownerNameController.text.trim());

      await prefs.setString('farm_name', _farmNameController.text.trim());

      await prefs.setString('owner_phone', _phoneController.text.trim());

      await prefs.setString('farm_address', _addressController.text.trim());

      await prefs.setDouble('predicted_daily_milk', prediction);

      // ------------------------------------------------------
      // Mark onboarding complete only after all local data
      // has been saved successfully.
      // ------------------------------------------------------

      await prefs.setBool('onboarding_completed', true);

      if (!mounted) return;

      context.go('/home');
    } catch (_) {
      if (!mounted) return;

      _showMessage('Unable to save farm details. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Farm Setup')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Set Up Your Farm',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Enter your farm information to get started.',
                style: theme.textTheme.bodyMedium,
              ),

              const SizedBox(height: 28),

              // =================================================
              // OWNER
              // =================================================
              Text(
                'Owner Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _ownerNameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Owner Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter owner name';
                  }

                  if (value.trim().length < 2) {
                    return 'Enter a valid name';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter phone number';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              // =================================================
              // FARM
              // =================================================
              Text(
                'Farm Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _farmNameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Farm Name',
                  prefixIcon: Icon(Icons.agriculture_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter farm name';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Farm Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter farm address';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              // =================================================
              // MILK PREDICTION
              // =================================================
              Text(
                'Daily Milk Prediction',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _predictionController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Predicted Daily Milk',
                  hintText: 'e.g. 150',
                  suffixText: 'L',
                  prefixIcon: Icon(Icons.water_drop_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter predicted milk';
                  }

                  final amount = double.tryParse(value.trim());

                  if (amount == null || amount <= 0) {
                    return 'Enter a valid milk quantity';
                  }

                  return null;
                },
                onFieldSubmitted: (_) {
                  if (!_isSaving) {
                    _completeOnboarding();
                  }
                },
              ),

              const SizedBox(height: 12),

              Text(
                'You can change this later from Settings.',
                style: theme.textTheme.bodySmall,
              ),

              const SizedBox(height: 32),

              // =================================================
              // COMPLETE
              // =================================================
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isSaving ? null : _completeOnboarding,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('COMPLETE SETUP'),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'You can add customers from the home screen after setup.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
