import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dairyfarmabuka/services/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService.instance;
});

final syncProvider = AsyncNotifierProvider<SyncNotifier, bool>(
  SyncNotifier.new,
);

class SyncNotifier extends AsyncNotifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  Future<bool> build() async {
    ref.onDispose(() {
      _connectivitySubscription?.cancel();
    });

    _listenToConnectivity();

    return false;
  }

  void _listenToConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final hasInternet = results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (hasInternet) {
        sync();
      }
    });
  }

  Future<void> sync() async {
    if (state.isLoading) {
      return;
    }

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(syncServiceProvider).syncNow();

      return true;
    });
  }
}
