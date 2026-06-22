import 'package:brightcleanproject/features/customer/data/models/booking_model.dart';
import 'package:brightcleanproject/features/customer/data/providers/cart_provider.dart';
import 'package:brightcleanproject/features/customer/data/providers/order_provider.dart';
import 'package:brightcleanproject/features/customer/domain/repositories/booking_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBookingRepository implements BookingRepository {
  List<Map<String, dynamic>>? createdItems;

  @override
  Future<List<BookingModel>> getMyBookings() async => [];

  @override
  Future<List<BookingModel>> getPendingBookings(int agentId) async => [];

  @override
  Future<void> acceptBooking(int bookingId) async {}

  @override
  Future<void> markBookingReady(int bookingId) async {}

  @override
  Future<double?> submitBooking(
    int bookingId, {
    DateTime? scheduledAt,
    String? specialInstructions,
  }) async =>
      42;

  @override
  Future<int> createBooking(
    int laundryAgentID,
    List<Map<String, dynamic>> items, {
    int? addressID,
    DateTime? scheduledAt,
    String? specialInstructions,
  }) async {
    createdItems = items;
    return 1001;
  }
}

class _TrackingCartProvider extends CartProvider {
  bool clearedSilently = false;

  _TrackingCartProvider() : super(loadFromDb: false);

  @override
  Future<void> clearCartSilently() async {
    clearedSilently = true;
  }
}

void main() {
  test('submitOrder does not clear cart before payment is recorded', () async {
    final cartProvider = _TrackingCartProvider();
    final orderProvider = OrderProvider(
      bookingRepository: _FakeBookingRepository(),
      cartProvider: cartProvider,
      initialize: false,
    );

    final total = await orderProvider.submitOrder(
      1001,
      notifyOnStateChange: false,
    );

    expect(total, 42);
    expect(cartProvider.clearedSilently, isFalse);
    expect(orderProvider.currentBookingId, isNull);
  });

  test('createBooking preserves submitted item unit prices', () async {
    final repository = _FakeBookingRepository();
    final orderProvider = OrderProvider(
      bookingRepository: repository,
      cartProvider: _TrackingCartProvider(),
      initialize: false,
    );

    await orderProvider.createBooking(
      7,
      [
        {
          'serviceID': 3,
          'quantity': 2,
          'unitPriceAtTimeOfBooking': 15.5,
        },
      ],
      notifyOnStateChange: false,
    );

    expect(repository.createdItems?.single['unitPriceAtTimeOfBooking'], 15.5);
  });
}
