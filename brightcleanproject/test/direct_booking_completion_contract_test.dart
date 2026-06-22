import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('direct bookings can only be completed after processing starts', () {
    final source = File(
      '../backend/BrightClean.API/Controllers/BookingsController.cs',
    ).readAsStringSync();

    expect(source, contains('Only in-progress technician dispatch bookings can be completed.'));
    expect(
      source,
      isNot(contains('booking.Status != BookingStatus.Accepted && booking.Status != BookingStatus.InProgress && booking.Status != BookingStatus.Ready')),
    );
    expect(source, contains('booking.Status != BookingStatus.InProgress'));
    expect(source, contains('tried to complete booking'));
  });
}
