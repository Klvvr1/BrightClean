import '../../../../core/enums/service_activation_status.dart';
import '../../../../core/utils/json_map_extension.dart';

class AgentServiceModel {
  final int agentId;
  final int serviceId;
  final String serviceName;
  final AgentServiceStatus status;
  final bool isActive;
  final bool pendingActivation;
  final String? description;
  final String? category;
  final String? imageUrl;
  final double? price;

  const AgentServiceModel({
    required this.agentId,
    required this.serviceId,
    required this.serviceName,
    required this.status,
    required this.isActive,
    required this.pendingActivation,
    this.description,
    this.category,
    this.imageUrl,
    this.price,
  });

  factory AgentServiceModel.fromJson(Map<String, dynamic> json) {
    final status = AgentServiceStatusParser.fromJson(json);
    final pendingActivation = json.readFirstBool(
      ['pendingActivation', 'PendingActivation'],
      fallback: status == AgentServiceStatus.pendingActivation,
    );
    final isActive = json.readFirstBool(
      ['isActive', 'IsActive'],
      fallback: status == AgentServiceStatus.active,
    );

    return AgentServiceModel(
      agentId: json.readFirstInt(['agentId', 'agentID', 'AgentID']),
      serviceId: json.readFirstInt([
        'serviceId',
        'serviceID',
        'ServiceID',
        'id',
        'ID',
        'serviceCatalogItemId',
        'serviceCatalogItemID',
      ]),
      serviceName: json.readFirstString(['serviceName', 'ServiceName']),
      status: status,
      isActive: isActive,
      pendingActivation: pendingActivation,
      description: json.readNullableString('description') ??
          json.readNullableString('Description'),
      category: json.readNullableString('category') ??
          json.readNullableString('Category'),
      imageUrl: json.readNullableString('imageUrl') ??
          json.readNullableString('ImageUrl'),
      price: _readNullableDouble(json, ['price', 'Price']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'status': status.name,
      'isActive': isActive,
      'pendingActivation': pendingActivation,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'price': price,
    };
  }

  static double? _readNullableDouble(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
