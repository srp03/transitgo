import '../../core/network/api_client.dart';
import '../models/bus_model.dart';

class BusRepository {
  final ApiClient apiClient;

  BusRepository(this.apiClient);

  Future<List<BusLocationModel>> getLiveBuses() async {
    final data = await apiClient.get('/buses/live');
    if (data is List) {
      return data.map((json) => BusLocationModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<BusLocationModel?> getBusLocation(int busId) async {
    final data = await apiClient.get('/buses/$busId/location');
    if (data is Map<String, dynamic>) {
      return BusLocationModel.fromJson(data);
    }
    return null;
  }
}
