import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/milk_delivery.dart';
import '../models/milk_entry.dart';
import '../models/customer.dart';
import '../repositories/milk_repository.dart';

final milkRepositoryProvider = Provider<MilkRepository>((ref) {
  return MilkRepository();
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

  return ref.read(milkRepositoryProvider).getDeliveries(entry.id!);
});

final todaySoldMilkProvider = FutureProvider.autoDispose<double>((ref) async {
  final entry = await ref.watch(todayMilkProvider.future);

  if (entry == null || entry.id == null) {
    return 0;
  }

  return ref.read(milkRepositoryProvider).soldMilk(entry.id!);
});

final todayRevenueProvider = FutureProvider.autoDispose<double>((ref) async {
  final entry = await ref.watch(todayMilkProvider.future);

  if (entry == null || entry.id == null) {
    return 0;
  }

  return ref.read(milkRepositoryProvider).revenue(entry.id!);
});

final todayRemainingMilkProvider = FutureProvider.autoDispose<double>((
  ref,
) async {
  final entry = await ref.watch(todayMilkProvider.future);

  if (entry == null || entry.id == null) {
    return 0;
  }

  return ref.read(milkRepositoryProvider).remainingMilk(entry.id!);
});

class TodayMilkNotifier extends AsyncNotifier<MilkEntry?> {
  MilkRepository get _repository => ref.read(milkRepositoryProvider);

  @override
  Future<MilkEntry?> build() async {
    return _repository.getEntryByDate(_today());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() => _repository.getEntryByDate(_today()));

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
