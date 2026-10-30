import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/stop_model.dart';
import 'core_providers.dart';
import 'location_provider.dart';

final allStopsProvider = FutureProvider<List<StopModel>>((ref) async {
  final repo = ref.watch(stopRepositoryProvider);
  return await repo.getAllStops();
});

final stopDetailProvider = FutureProvider.family<StopWithRoutesModel?, int>((ref, stopId) async {
  final repo = ref.watch(stopRepositoryProvider);
  return await repo.getStopById(stopId);
});

final nearbyStopsProvider = FutureProvider<List<StopModel>>((ref) async {
  final location = ref.watch(locationProvider);
  final repo = ref.watch(stopRepositoryProvider);
  return await repo.getNearbyStops(
    latitude: location.latitude,
    longitude: location.longitude,
    radiusKm: 5.0,
  );
});

final stopSearchProvider = FutureProvider.family<List<StopModel>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(stopRepositoryProvider);
  return await repo.searchStops(query);
});
