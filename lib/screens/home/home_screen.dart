import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/customer_provider.dart';
import '../../providers/milk_provider.dart';
import '../../providers/owner_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerAsync = ref.watch(ownerProvider);
    final customersAsync = ref.watch(customerProvider);
    final milkAsync = ref.watch(todayMilkProvider);
    final soldAsync = ref.watch(todaySoldMilkProvider);
    final revenueAsync = ref.watch(todayRevenueProvider);
    final remainingAsync = ref.watch(todayRemainingMilkProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              context.push('/home/settings');
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(ownerProvider.notifier).loadOwner(),
            ref.read(customerProvider.notifier).refresh(),
            ref.read(todayMilkProvider.notifier).refresh(),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            ownerAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Unable to load farm details.'),
              data: (owner) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner == null ? 'Hello 👋' : 'Hello, ${owner.name} 👋',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      owner?.farmName ?? 'Your Dairy Farm',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              'Today',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _AnalyticsCard(
                    title: 'Production',
                    value: milkAsync.when(
                      loading: () => '...',
                      error: (_, _) => '0 L',
                      data: (entry) => entry == null
                          ? '0 L'
                          : '${entry.totalProduction.toStringAsFixed(1)} L',
                    ),
                    icon: Icons.water_drop_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AnalyticsCard(
                    title: 'Delivered',
                    value: soldAsync.when(
                      loading: () => '...',
                      error: (_, _) => '0 L',
                      data: (value) => '${value.toStringAsFixed(1)} L',
                    ),
                    icon: Icons.local_shipping_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _AnalyticsCard(
                    title: 'Customers',
                    value: customersAsync.when(
                      loading: () => '...',
                      error: (_, _) => '0',
                      data: (customers) => customers.length.toString(),
                    ),
                    icon: Icons.people_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AnalyticsCard(
                    title: 'Remaining',
                    value: remainingAsync.when(
                      loading: () => '...',
                      error: (_, _) => '0 L',
                      data: (value) => '${value.toStringAsFixed(1)} L',
                    ),
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _RevenueCard(revenueAsync: revenueAsync),

            const SizedBox(height: 28),

            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    title: 'Add Milk',
                    subtitle: 'Record today\'s milk',
                    icon: Icons.water_drop_outlined,
                    onTap: () async {
                      final result = await context.push<bool>('/home/milk/add');

                      if (result == true) {
                        ref.read(todayMilkProvider.notifier).refresh();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    title: 'Customers',
                    subtitle: 'Manage customers',
                    icon: Icons.people_outline,
                    onTap: () {
                      context.push('/home/customers');
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            ownerAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (owner) {
                if (owner == null) {
                  return const SizedBox.shrink();
                }

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.insights_outlined),
                    title: const Text('Daily Target'),
                    subtitle: Text(
                      '${owner.prediction.toStringAsFixed(1)} L predicted',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/home/milk/add');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Milk'),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.revenueAsync});

  final AsyncValue<double> revenueAsync;

  @override
  Widget build(BuildContext context) {
    final revenue = revenueAsync.when(
      loading: () => '...',
      error: (_, _) => '0',
      data: (value) => value.toStringAsFixed(2),
    );

    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
        title: const Text('Today\'s Revenue'),
        subtitle: const Text('Total value of delivered milk'),
        trailing: Text(
          'Rs. $revenue',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
