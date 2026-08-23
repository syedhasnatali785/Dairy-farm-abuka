import 'package:dairyfarmabuka/screens/customers/add_customer_screen.dart';
import 'package:dairyfarmabuka/screens/customers/customer_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/milk/add_milk_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',

  debugLogDiagnostics: false,

  routes: [
    // ==========================================================
    // SPLASH
    // ==========================================================
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) {
        return const SplashScreen();
      },
    ),

    // ==========================================================
    // AUTH
    // ==========================================================
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) {
        return const LoginScreen();
      },
    ),

    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) {
        return const RegisterScreen();
      },
    ),

    // ==========================================================
    // ONBOARDING
    // ==========================================================
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) {
        return const OnboardingScreen();
      },
    ),

    // ==========================================================
    // HOME
    // ==========================================================
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) {
        return const HomeScreen();
      },
      routes: [
        // ======================================================
        // CUSTOMERS
        // ======================================================
        GoRoute(
          path: 'customers',
          name: 'customers',
          builder: (context, state) {
            return const CustomerListScreen();
          },
          routes: [
            GoRoute(
              path: 'add',
              name: 'addCustomer',
              builder: (context, state) {
                return const AddCustomerScreen();
              },
            ),
          ],
        ),

        // ======================================================
        // MILK
        // ======================================================
        GoRoute(
          path: 'milk/add',
          name: 'addMilk',
          builder: (context, state) {
            return const AddMilkScreen();
          },
        ),

        // ======================================================
        // SETTINGS
        // ======================================================
        GoRoute(
          path: 'settings',
          name: 'settings',
          builder: (context, state) {
            return const SettingsScreen();
          },
        ),
      ],
    ),
  ],

  // ==========================================================
  // ERROR
  // ==========================================================
  errorBuilder: (context, state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text('Page not found\n${state.uri}', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  context.go('/home');
                },
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
