import '../../../../core/network/api_client.dart';
import '../../domain/repositories/booking_repository.dart';
import '../models/booking_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BaseApiClient apiClient;

  BookingRepositoryImpl({required this.apiClient});

  @override
  Future<List<BookingModel>> getPendingBookings(int agentId) async {
    try {
      final response = await apiClient.get('/api/bookings/agent/$agentId/pending');
      
      if (response != null && response is Map<String, dynamic> && response.containsKey('value')) {
        final list = response['value'] as List<dynamic>;
        return list
            .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> acceptBooking(int bookingId) async {
    try {
      await apiClient.post('/api/bookings/$bookingId/accept');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> markBookingReady(int bookingId) async {
    try {
      await apiClient.post('/api/bookings/$bookingId/ready');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> submitBooking(int bookingId) async {
    try {
      await apiClient.post(
        '/api/bookings/submit',
        body: {'bookingID': bookingId},
      );
    } catch (e) {
      rethrow;
    }
  }
}
