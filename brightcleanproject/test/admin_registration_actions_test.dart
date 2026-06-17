import 'package:brightcleanproject/core/network/api_client.dart';
import 'package:brightcleanproject/features/admin/data/models/admin_audit_log_model.dart';
import 'package:brightcleanproject/features/admin/data/models/admin_summary_model.dart';
import 'package:brightcleanproject/features/admin/data/models/pending_user_model.dart';
import 'package:brightcleanproject/features/admin/data/providers/admin_provider.dart';
import 'package:brightcleanproject/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:brightcleanproject/features/admin/domain/repositories/admin_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _PostTrackingApiClient extends BaseApiClient {
  String? requestedEndpoint;

  @override
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    requestedEndpoint = endpoint;
    return {'message': 'ok'};
  }
}

class _RegistrationRepository implements AdminRepository {
  int? approvedUserId;
  int? rejectedUserId;
  int pendingRefreshCount = 0;
  int approvedStaffRefreshCount = 0;
  int auditRefreshCount = 0;

  @override
  Future<void> approveUser(int userId) async {
    approvedUserId = userId;
  }

  @override
  Future<void> rejectUser(int userId) async {
    rejectedUserId = userId;
  }

  @override
  Future<List<PendingUserModel>> getPendingApprovals() async {
    pendingRefreshCount++;
    return const [];
  }

  @override
  Future<List<dynamic>> getApprovedStaff() async {
    approvedStaffRefreshCount++;
    return const [];
  }

  @override
  Future<List<AdminAuditLogModel>> getAuditLogs() async {
    auditRefreshCount++;
    return const [];
  }

  @override
  Future<AdminSummaryModel> getSummary() async => AdminSummaryModel.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('AdminRepositoryImpl rejects users through admin endpoint', () async {
    final apiClient = _PostTrackingApiClient();
    final repository = AdminRepositoryImpl(apiClient: apiClient);

    await repository.rejectUser(42);

    expect(apiClient.requestedEndpoint, '/api/admin/reject/42');
  });

  test('AdminProvider refreshes pending, approved staff, and audit logs after approval',
      () async {
    final repository = _RegistrationRepository();
    final provider = AdminProvider(adminRepository: repository);

    await provider.approveUser(7);

    expect(repository.approvedUserId, 7);
    expect(repository.pendingRefreshCount, 1);
    expect(repository.approvedStaffRefreshCount, 1);
    expect(repository.auditRefreshCount, 1);
    expect(provider.isActionLoading, isFalse);
  });

  test('AdminProvider refreshes pending and audit logs after rejection', () async {
    final repository = _RegistrationRepository();
    final provider = AdminProvider(adminRepository: repository);

    await provider.rejectUser(9);

    expect(repository.rejectedUserId, 9);
    expect(repository.pendingRefreshCount, 1);
    expect(repository.approvedStaffRefreshCount, 0);
    expect(repository.auditRefreshCount, 1);
    expect(provider.isActionLoading, isFalse);
  });
}
