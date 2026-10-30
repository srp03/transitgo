import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/storage/preferences_service.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/bus_repository.dart';
import '../data/repositories/notice_repository.dart';
import '../data/repositories/route_repository.dart';
import '../data/repositories/stop_repository.dart';

// Must be overridden in ProviderScope in main.dart
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError('preferencesServiceProvider not initialized');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return ApiClient(preferencesService: prefs);
});

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return RouteRepository(client);
});

final stopRepositoryProvider = Provider<StopRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return StopRepository(client);
});

final busRepositoryProvider = Provider<BusRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return BusRepository(client);
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return BookingRepository(client);
});

final noticeRepositoryProvider = Provider<NoticeRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return NoticeRepository(client);
});
