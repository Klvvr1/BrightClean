import '../../data/models/booking_model.dart';

abstract class BookingRepository {
  Future<List<BookingModel>> getPendingBookings(int agentId);
  Future<void> acceptBooking(int bookingId);
  Future<void> markBookingReady(int bookingId);
  Future<double?> submitBooking(int bookingId);
  Future<int> createBooking(int laundryAgentID, List<Map<String, int>> items, {int? addressID});
}
