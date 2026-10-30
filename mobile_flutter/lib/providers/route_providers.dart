import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/bus_model.dart';
import '../data/models/route_model.dart';
import '../data/models/schedule_model.dart';
import '../data/models/stop_model.dart';
import 'core_providers.dart';

final routesListProvider = FutureProvider<List<RouteModel>>((ref) async {
  final repo = ref.watch(routeRepositoryProvider);
  return await repo.getAllRoutes();
});

final routeDetailProvider = FutureProvider.family<RouteModel?, int>((ref, routeId) async {
  final repo = ref.watch(routeRepositoryProvider);
  return await repo.getRouteById(routeId);
});

final routeStopsProvider = FutureProvider.family<List<StopModel>, int>((ref, routeId) async {
  final repo = ref.watch(routeRepositoryProvider);
  return await repo.getRouteStops(routeId);
});

final routeScheduleProvider = FutureProvider.family<List<ScheduleModel>, int>((ref, routeId) async {
  final repo = ref.watch(routeRepositoryProvider);
  return await repo.getRouteSchedule(routeId);
});

final routeBusesProvider = FutureProvider.family<List<BusLocationModel>, int>((ref, routeId) async {
  final repo = ref.watch(routeRepositoryProvider);
  return await repo.getRouteBuses(routeId);
});

// Journey Search Parameters
class SearchParams {
  final String from;
  final String to;

  const SearchParams({this.from = '', this.to = ''});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchParams &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => from.hashCode ^ to.hashCode;
}

final routeSearchProvider = FutureProvider.family<List<RouteModel>, SearchParams>((ref, params) async {
  final repo = ref.watch(routeRepositoryProvider);
  if (params.from.trim().isEmpty && params.to.trim().isEmpty) {
    return [];
  }
  return await repo.searchRoutes(from: params.from, to: params.to);
});

// Favourites State Notifier using Riverpod 3 Notifier
class FavouritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return prefs.getFavouriteRouteIds().toSet();
  }

  Future<void> toggleFavourite(String routeId) async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.toggleFavouriteRouteId(routeId);
    state = prefs.getFavouriteRouteIds().toSet();
  }

  bool isFavourite(String routeId) {
    return state.contains(routeId);
  }
}

final favouritesProvider = NotifierProvider<FavouritesNotifier, Set<String>>(FavouritesNotifier.new);

// Recent Searches Notifier using Riverpod 3 Notifier
class RecentSearchesNotifier extends Notifier<List<Map<String, String>>> {
  @override
  List<Map<String, String>> build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return prefs.getRecentSearches();
  }

  Future<void> addSearch(String from, String to) async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.addRecentSearch(from, to);
    state = prefs.getRecentSearches();
  }

  Future<void> clearAll() async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.clearRecentSearches();
    state = [];
  }
}

final recentSearchesProvider = NotifierProvider<RecentSearchesNotifier, List<Map<String, String>>>(RecentSearchesNotifier.new);
