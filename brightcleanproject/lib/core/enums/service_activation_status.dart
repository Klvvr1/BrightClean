import '../utils/json_map_extension.dart';

enum AgentServiceStatus {
  active,
  inactive,
  pendingActivation,
  unknown,
}

enum ActivationRequestType {
  activation,
  deactivation,
  unknown,
}

enum ActivationRequestStatus {
  pending,
  approved,
  rejected,
  unknown,
}

String _normalizeActivationValue(Object? value) {
  return value
          ?.toString()
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[\s_-]+'), '') ??
      '';
}

extension AgentServiceStatusParser on AgentServiceStatus {
  static AgentServiceStatus fromValue(Object? value) {
    switch (_normalizeActivationValue(value)) {
      case 'active':
        return AgentServiceStatus.active;
      case 'inactive':
        return AgentServiceStatus.inactive;
      case 'pendingactivation':
        return AgentServiceStatus.pendingActivation;
      default:
        return AgentServiceStatus.unknown;
    }
  }

  static AgentServiceStatus fromJson(Map<String, dynamic> json) {
    for (final key in [
      'status',
      'Status',
      'serviceStatus',
      'ServiceStatus',
      'activationStatus',
      'ActivationStatus',
    ]) {
      final status = fromValue(json.readValue(key));
      if (status != AgentServiceStatus.unknown) return status;
    }

    if (json.readFirstBool(['pendingActivation', 'PendingActivation'])) {
      return AgentServiceStatus.pendingActivation;
    }

    final isActive =
        json.readNullableBool('isActive') ?? json.readNullableBool('IsActive');
    if (isActive == true) return AgentServiceStatus.active;
    if (isActive == false) return AgentServiceStatus.inactive;

    return AgentServiceStatus.unknown;
  }
}

extension ActivationRequestTypeParser on ActivationRequestType {
  static ActivationRequestType fromValue(Object? value) {
    switch (_normalizeActivationValue(value)) {
      case 'activation':
      case 'activate':
        return ActivationRequestType.activation;
      case 'deactivation':
      case 'deactivate':
        return ActivationRequestType.deactivation;
      default:
        return ActivationRequestType.unknown;
    }
  }
}

extension ActivationRequestStatusParser on ActivationRequestStatus {
  static ActivationRequestStatus fromValue(Object? value) {
    switch (_normalizeActivationValue(value)) {
      case 'pending':
        return ActivationRequestStatus.pending;
      case 'approved':
        return ActivationRequestStatus.approved;
      case 'rejected':
        return ActivationRequestStatus.rejected;
      default:
        return ActivationRequestStatus.unknown;
    }
  }
}
