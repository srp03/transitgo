import '../../core/network/api_client.dart';
import '../models/stop_model.dart';

class StopRepository {
  final ApiClient apiClient;

  StopRepository(this.apiClient);

  Future<List<StopModel>> getAllStops() async {
    final data = await apiClient.get('/stops');
    if (data is List) {
      return data.map((json) => StopModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<StopWithRoutesModel?> getStopById(int id) async {
    final data = await apiClient.get('/stops/$id');
    if (data is Map<String, dynamic>) {
      return StopWithRoutesModel.fromJson(data);
    }
    return null;
  }

  Future<List<StopModel>> getNearbyStops({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    final data = await apiClient.get('/stops/nearby', queryParameters: {
      'lat': latitude,
      'lng': longitude,
      'radius': radiusKm,
    });
    if (data is List) {
      return data.map((json) => StopModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<StopModel>> searchStops(String query) async {
    if (query.trim().isEmpty) return [];
    final data = await apiClient.get('/stops/search', queryParameters: {
      'query': query.trim(),
    });
    if (data is List) {
      return data.map((json) => StopModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
