import 'package:dairyfarmabuka/services/shared_pref_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sharedPrefServiceProvider = Provider<SharedPrefService>((ref) {
  return SharedPrefService();
});
final appStartupProvider = FutureProvider<bool>((ref) {
  final service = ref.read(sharedPrefServiceProvider);
  return service.isRegistered();
});
