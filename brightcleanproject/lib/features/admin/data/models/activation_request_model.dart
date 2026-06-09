import '../../../../core/enums/service_activation_status.dart';
import '../../../../core/utils/json_map_extension.dart';

class ActivationRequestModel {
  final int agentId;
  final int serviceId;
  final String agentName;
  final String serviceName;
  final ActivationRequestType requestType;
  final DateTime? requestDate;
  final ActivationRequestStatus status;

  const ActivationRequestModel({
    required this.agentId,
    required this.serviceId,
    required this.agentName,
    required this.serviceName,
    required this.requestType,
    required this.requestDate,
    required this.status,
  });

  factory ActivationRequestModel.fromJson(Map<String, dynamic> json) {
    return ActivationRequestModel(
      agentId: json.readFirstInt(['agentId', 'agentID', 'AgentID']),
      serviceId: json.readFirstInt(['serviceId', 'serviceID', 'ServiceID']),
      agentName: json.readFirstString([
        'agentName',
        'AgentName',
        'laundryName',
        'LaundryName',
        'businessName',
        'BusinessName',
      ]),
      serviceName: json.readFirstString(['serviceName', 'ServiceName']),
      requestType: ActivationRequestTypeParser.fromValue(
        json.readValue('requestType') ??
            json.readValue('RequestType') ??
            json.readValue('requestedAction') ??
            json.readValue('RequestedAction') ??
            json.readValue('type') ??
            json.readValue('Type'),
      ),
      requestDate: json.readFirstNullableDateTime([
        'requestDate',
        'RequestDate',
        'createdAt',
        'CreatedAt',
      ]),
      status: ActivationRequestStatusParser.fromValue(
        json.readValue('status') ??
            json.readValue('activationRequestStatus') ??
            json.readValue('ActivationRequestStatus') ??
            json.readValue('Status') ??
            (json.readFirstBool(['pendingActivation', 'PendingActivation'])
                ? 'Pending'
                : null),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'serviceId': serviceId,
      'agentName': agentName,
      'serviceName': serviceName,
      'requestType': requestType.name,
      'requestDate': requestDate?.toIso8601String(),
      'status': status.name,
    };
  }
}
