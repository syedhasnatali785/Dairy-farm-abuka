import 'package:dairyfarmabuka/providers/auth_provider.dart';
import 'package:dairyfarmabuka/providers/owner_provider.dart';
import 'package:dairyfarmabuka/screens/auth/login_screen.dart';
import 'package:dairyfarmabuka/screens/home/home_screen.dart';
import 'package:dairyfarmabuka/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }
        return const _OwnerGate();
      },
      error: (error, stackTrace) => _ErrorScreen(message: error.toString()),
      loading: () => const _LoadingScreen(),
    );
  }
}

class _OwnerGate extends ConsumerWidget {
  const _OwnerGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerState = ref.watch(ownerProvider);
    return ownerState.when(
      data: (owner) {
        if (owner == null || !owner.onboardingCompleted) {
          return OnboardingScreen();
        }
        return const HomeScreen();
      },
      error: (error, stackTrace) => _ErrorScreen(message: error.toString()),
      loading: () => const _LoadingScreen(),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;

  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Riverpod automatically retries
                  // when providers are refreshed.
                },
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
