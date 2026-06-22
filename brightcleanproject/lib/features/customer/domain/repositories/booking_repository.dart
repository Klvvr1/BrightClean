import '../../data/models/booking_model.dart';

abstract class BookingRepository {
  Future<List<BookingModel>> getMyBookings();
  Future<List<BookingModel>> getPendingBookings(int agentId);
  Future<void> acceptBooking(int bookingId);
  Future<void> markBookingReady(int bookingId);
  Future<double?> submitBooking(
    int bookingId, {
    DateTime? scheduledAt,
    String? specialInstructions,
  });
  Future<int> createBooking(
    int laundryAgentID,
    List<Map<String, dynamic>> items, {
    int? addressID,
    DateTime? scheduledAt,
    String? specialInstructions,
  });
}
