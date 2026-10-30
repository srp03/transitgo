import '../../core/network/api_client.dart';
import '../models/bus_model.dart';
import '../models/route_model.dart';
import '../models/schedule_model.dart';
import '../models/stop_model.dart';

class RouteRepository {
  final ApiClient apiClient;

  RouteRepository(this.apiClient);

  Future<List<RouteModel>> getAllRoutes() async {
    final data = await apiClient.get('/routes');
    if (data is List) {
      return data.map((json) => RouteModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<RouteModel?> getRouteById(int id) async {
    final data = await apiClient.get('/routes/$id');
    if (data is Map<String, dynamic>) {
      return RouteModel.fromJson(data);
    }
    return null;
  }

  Future<List<StopModel>> getRouteStops(int id) async {
    final data = await apiClient.get('/routes/$id/stops');
    if (data is List) {
      return data.map((json) => StopModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<ScheduleModel>> getRouteSchedule(int id) async {
    final data = await apiClient.get('/routes/$id/schedule');
    if (data is List) {
      return data.map((json) => ScheduleModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<BusLocationModel>> getRouteBuses(int id) async {
    final data = await apiClient.get('/routes/$id/buses');
    if (data is List) {
      return data.map((json) => BusLocationModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<RouteModel>> searchRoutes({String? from, String? to}) async {
    final queryParams = <String, dynamic>{};
    if (from != null && from.trim().isNotEmpty) {
      queryParams['from'] = from.trim();
    }
    if (to != null && to.trim().isNotEmpty) {
      queryParams['to'] = to.trim();
    }
    final data = await apiClient.get('/routes/search', queryParameters: queryParams);
    if (data is List) {
      return data.map((json) => RouteModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
