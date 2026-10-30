import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/bus_model.dart';
import 'core_providers.dart';

final liveBusesProvider = FutureProvider.autoDispose<List<BusLocationModel>>((ref) async {
  final repo = ref.watch(busRepositoryProvider);
  return await repo.getLiveBuses();
});

final busLocationProvider = FutureProvider.family.autoDispose<BusLocationModel?, int>((ref, busId) async {
  final repo = ref.watch(busRepositoryProvider);
  return await repo.getBusLocation(busId);
});
