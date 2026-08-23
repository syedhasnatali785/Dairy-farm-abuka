import 'package:dairyfarmabuka/models/customer.dart';
import 'package:dairyfarmabuka/models/milk_delivery.dart';
import 'package:dairyfarmabuka/models/milk_entry.dart';
import 'package:dairyfarmabuka/repositories/milk_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final milkRepositoryProvider = Provider((ref) => MilkRepository());
final milkProvider = AsyncNotifierProvider<MilkNotifier, MilkDashboardState>(
  MilkNotifier.new,
);

class MilkDashboardState {
  final MilkEntry? todayEntry;
  final double production;
  final double sold;
  final double remaining;
  final double revenue;

  const MilkDashboardState({
    this.todayEntry,
    this.production = 0,
    this.sold = 0,
    this.remaining = 0,
    this.revenue = 0,
  });
  MilkDashboardState copyWith({
    MilkEntry? todayEntry,
    double? production,
    double? sold,
    double? remaining,
    double? revenue,
  }) {
    return MilkDashboardState(
      todayEntry: todayEntry ?? this.todayEntry,
      production: production ?? this.production,
      sold: sold ?? this.sold,
      remaining: remaining ?? this.remaining,
      revenue: revenue ?? this.revenue,
    );
  }
}

class MilkNotifier extends AsyncNotifier<MilkDashboardState> {
  MilkRepository get _repository => ref.read(milkRepositoryProvider);
  @override
  Future<MilkDashboardState> build() async {
    return _loadToday();
  }

  Future<MilkDashboardState> _loadToday() async {
    final today = _formatDate(DateTime.now());
    final entry = await _repository.getEntryByDate(today);
    if (entry == null) {
      return const MilkDashboardState();
    }
    final sold = await _repository.soldMilk(entry.id!);
    final revenue = await _repository.revenue(entry.id!);

    final remaining = entry.totalProduction - sold;
    return MilkDashboardState(
      todayEntry: entry,
      production: entry.totalProduction,
      sold: sold,
      remaining: remaining,
      revenue: revenue,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(_loadToday);
  }

  Future<bool> saveDay({
    required double totalProduction,
    required List<Customer> customers,
    required Map<int, bool> selectedCustomers,
    required bool boughtMode,
  }) async {
    if (totalProduction < 0) {
      return false;
    }
    try {
      final today = _formatDate(DateTime.now());
      final existingEntry = await _repository.getEntryByDate(today);
      if (existingEntry != null) {
        return false;
      }
      final entry = MilkEntry(date: today, totalProduction: totalProduction);
      await _repository.saveDay(
        entry: entry,
        customers: customers,
        selectedCustomers: selectedCustomers,
        boughtMode: boughtMode,
      );
      await refresh();
      return true;
    } catch (e, StackTrace) {
      state = AsyncError(e, StackTrace);
      return false;
    }
  }

  Future<MilkEntry?> getEntryByDate(String date) {
    return _repository.getEntryByDate(date);
  }

  Future<List<MilkDelivery>> getDeliveries(int milkEntryId) {
    return _repository.getDeliveries(milkEntryId);
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
