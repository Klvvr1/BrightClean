import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin live orders section uses backend data instead of dummy list', () {
    final screenSource = File(
      'lib/features/admin/presentation/admin_dashboard_screen.dart',
    ).readAsStringSync();
    final repositorySource = File(
      'lib/features/admin/data/repositories/admin_repository_impl.dart',
    ).readAsStringSync();
    final providerSource = File(
      'lib/features/admin/data/providers/admin_provider.dart',
    ).readAsStringSync();
    final contractSource = File(
      'lib/features/admin/domain/repositories/admin_repository.dart',
    ).readAsStringSync();
    final backendSource = File(
      '../backend/BrightClean.API/Controllers/AdminController.cs',
    ).readAsStringSync();

    expect(screenSource, isNot(contains('Dummy data for live orders')));
    expect(screenSource, isNot(contains('final List<Map<String, dynamic>> _liveOrders = []')));
    expect(screenSource, contains('_buildLiveOrdersSection(adminProvider.liveOrders)'));
    expect(providerSource, contains('List<dynamic> get liveOrders => _liveOrders;'));
    expect(providerSource, contains('fetchLiveOrders()'));
    expect(contractSource, contains('Future<List<dynamic>> getLiveOrders();'));
    expect(repositorySource, contains("'/api/admin/live-orders'"));
    expect(backendSource, contains('[HttpGet("live-orders")]'));
    expect(backendSource, contains('BookingStatus.Completed'));
    expect(backendSource, contains('BookingStatus.Cancelled'));
  });
}
