import '../../core/network/api_client.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final ApiClient apiClient;

  BookingRepository(this.apiClient);

  Future<BookingModel> createBooking(CreateBookingRequest request) async {
    final data = await apiClient.post('/bookings', data: request.toJson());
    if (data is Map<String, dynamic>) {
      return BookingModel.fromJson(data);
    }
    throw Exception('Failed to create booking: invalid response format');
  }

  Future<List<BookingModel>> getAllBookings() async {
    final data = await apiClient.get('/bookings');
    if (data is List) {
      return data.map((json) => BookingModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<BookingModel?> getBookingById(int id) async {
    final data = await apiClient.get('/bookings/$id');
    if (data is Map<String, dynamic>) {
      return BookingModel.fromJson(data);
    }
    return null;
  }

  Future<BookingModel?> getBookingByReference(String reference) async {
    final data = await apiClient.get('/bookings/ref/$reference');
    if (data is Map<String, dynamic>) {
      return BookingModel.fromJson(data);
    }
    return null;
  }

  Future<BookingModel?> cancelBooking(int id) async {
    final data = await apiClient.post('/bookings/$id/cancel');
    if (data is Map<String, dynamic>) {
      return BookingModel.fromJson(data);
    }
    return null;
  }
}
