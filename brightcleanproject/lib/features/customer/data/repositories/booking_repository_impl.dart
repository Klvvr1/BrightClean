import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/booking_repository.dart';
import '../models/booking_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BaseApiClient apiClient;

  BookingRepositoryImpl({required this.apiClient});

  List<BookingModel> _parseBookingList(dynamic response) {
    if (response is List) {
      return response
          .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    if (response != null &&
        response is Map<String, dynamic> &&
        response.containsKey('value') &&
        response['value'] is List) {
      return (response['value'] as List<dynamic>)
          .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<BookingModel>> getMyBookings() async {
    final response = await apiClient.get('/api/bookings/my');
    return _parseBookingList(response);
  }

  @override
  Future<List<BookingModel>> getPendingBookings(int agentId) async {
    try {
      final response = await apiClient.get('/api/bookings/agent/$agentId/pending');
      return _parseBookingList(response);
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
  Future<double?> submitBooking(
    int bookingId, {
    DateTime? scheduledAt,
    String? specialInstructions,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/bookings/submit',
        body: {
          'bookingID': bookingId,
          if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
          if (specialInstructions != null && specialInstructions.isNotEmpty)
            'specialInstructions': specialInstructions,
        },
      );
      debugPrint('📦 submitBooking response type: ${response.runtimeType}');
      debugPrint('📦 submitBooking response: $response');
      // The backend returns the updated booking with FinalTotal
      if (response != null && response is Map<String, dynamic>) {
        final rawTotal = response['finalTotal'] ?? response['FinalTotal'];
        debugPrint('📦 rawTotal: $rawTotal (type: ${rawTotal?.runtimeType})');
        if (rawTotal != null) {
          return (rawTotal as num).toDouble();
        }
      }
      // Return null to indicate server omitted total (distinguishable from genuine zero)
      return null;
    } catch (e) {
      debugPrint('❌ submitBooking error: $e');
      rethrow;
    }
  }

  @override
  Future<int> createBooking(
    int laundryAgentID,
    List<Map<String, dynamic>> items, {
    int? addressID,
    DateTime? scheduledAt,
    String? specialInstructions,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/bookings',
        body: {
          'laundryAgentID': laundryAgentID,
          'items': items,
          if (addressID != null) 'addressID': addressID,
          if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
          if (specialInstructions != null && specialInstructions.isNotEmpty)
            'specialInstructions': specialInstructions,
        },
      );
      if (response != null && response is Map<String, dynamic>) {
        final bookingId = response['bookingID'] ?? response['bookingId'];
        if (bookingId != null) {
          return bookingId as int;
        }
      }
      throw Exception('فشل إنشاء الحجز في الخادم.');
    } catch (e) {
      rethrow;
    }
  }
}
