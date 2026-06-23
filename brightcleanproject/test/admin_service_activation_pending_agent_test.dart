import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('service activation request details opens only for approved agents', () {
    final screenSource = File(
      'lib/features/admin/presentation/admin_dashboard_screen.dart',
    ).readAsStringSync();
    final modelSource = File(
      'lib/features/admin/data/models/activation_request_model.dart',
    ).readAsStringSync();

    expect(modelSource, contains('bool get canShowDetails'));
    expect(modelSource, contains("agentAccountStatus.toLowerCase() == 'active'"));
    expect(screenSource, contains('request.canShowDetails'));
    expect(screenSource, contains('_showServiceActivationRequestDetails(request)'));
  });

  test('backend requires laundry approval before service decisions', () {
    final source = File(
      '../backend/BrightClean.API/Controllers/AdminController.cs',
    ).readAsStringSync();

    expect(source, contains('Include(service => service.LaundryAgent)'));
    expect(source, contains('AgentIsApproved = service.LaundryAgent.IsApproved'));
    expect(source,
        contains('AgentAccountStatus = service.LaundryAgent.AccountStatus.ToString()'));
    expect(source, contains('agentService.LaundryAgent == null'));
    expect(source, contains('agentService.LaundryAgent.AccountStatus != AccountStatus.Active'));
  });
}
