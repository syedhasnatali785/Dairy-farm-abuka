import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import '../models/milk_delivery.dart';
import '../models/milk_entry.dart';
import '../repositories/firestore_milk_repository.dart';
import '../repositories/milk_repository.dart';

class UnifiedMilkRepository {
  final MilkRepository local = MilkRepository();
  final FirestoreMilkRepository remote = FirestoreMilkRepository();

  Future<void> saveDay({
    required MilkEntry entry,
    required List<Customer> customers,
    required Map<int, double> selectedCustomers,
  }) async {
    final deliveries = <MilkDelivery>[];

    for (final customer in customers) {
      final customerId = customer.id;
      if (customerId == null) continue;

      final deliveredMilk = selectedCustomers[customerId] ?? customer.dailyMilk;
      if (deliveredMilk <= 0) continue;

      deliveries.add(
        MilkDelivery(
          milkEntryId: 0,
          customerId: customerId,
          deliveredMilk: deliveredMilk,
          pricePerLiter: customer.pricePerLiter,
          bought: true,
        ),
      );
    }

    await Future.wait([
      local.saveDay(
        entry: entry,
        customers: customers,
        selectedCustomers: selectedCustomers,
      ),
      _saveRemote(entry, deliveries),
    ]);
  }

  Future<void> _saveRemote(
    MilkEntry entry,
    List<MilkDelivery> deliveries,
  ) async {
    if (FirebaseAuth.instance.currentUser == null) return;

    await remote.saveDay(
      date: DateTime.parse(entry.date),
      totalProduction: entry.totalProduction,
      deliveries: deliveries,
    );
  }
}

final milkRepositoryProvider = Provider<UnifiedMilkRepository>((ref) {
  return UnifiedMilkRepository();
});

final todayMilkProvider = AsyncNotifierProvider<TodayMilkNotifier, MilkEntry?>(
  TodayMilkNotifier.new,
);

final todayDeliveriesProvider = FutureProvider.autoDispose<List<MilkDelivery>>((
  ref,
) async {
  final entry = await ref.watch(todayMilkProvider.future);

  if (entry == null || entry.id == null) {
    return [];
  }

  return ref.read(milkRepositoryProvider).local.getDeliveries(entry.id!);
});

final todaySoldMilkProvider = FutureProvider.autoDispose<double>((ref) async {
  final entry = await ref.watch(todayMilkProvider.future);

  if (entry == null || entry.id == null) {
    return 0;
  }

  return ref.read(milkRepositoryProvider).local.soldMilk(entry.id!);
});

final todayRevenueProvider = FutureProvider.autoDispose<double>((ref) async {
  final entry = await ref.watch(todayMilkProvider.future);

  if (entry == null || entry.id == null) {
    return 0;
  }

  return ref.read(milkRepositoryProvider).local.revenue(entry.id!);
});

final todayRemainingMilkProvider = FutureProvider.autoDispose<double>((
  ref,
) async {
  final entry = await ref.watch(todayMilkProvider.future);

  if (entry == null || entry.id == null) {
    return 0;
  }

  return ref.read(milkRepositoryProvider).local.remainingMilk(entry.id!);
});

class TodayMilkNotifier extends AsyncNotifier<MilkEntry?> {
  UnifiedMilkRepository get _repository => ref.read(milkRepositoryProvider);

  @override
  Future<MilkEntry?> build() async {
    return _repository.local.getEntryByDate(_today());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.local.getEntryByDate(_today()),
    );

    ref.invalidate(todayDeliveriesProvider);
    ref.invalidate(todaySoldMilkProvider);
    ref.invalidate(todayRevenueProvider);
    ref.invalidate(todayRemainingMilkProvider);
  }

  Future<void> saveDay({
    required MilkEntry entry,
    required List<Customer> customers,
    required Map<int, double> selectedCustomers,
  }) async {
    await _repository.saveDay(
      entry: entry,
      customers: customers,
      selectedCustomers: selectedCustomers,
    );
    await refresh();
  }

  String _today() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
