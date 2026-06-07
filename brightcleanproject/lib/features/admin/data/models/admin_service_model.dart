class AdminServiceModel {
  final int serviceID;
  final String serviceName;
  final int category;
  final int type;
  final double price;
  final int pricingModel;
  final int deliveryModel;
  final bool isAvailable;
  final bool isDeleted;
  final int linkedAgentCount;
  final int activeAgentCount;
  final bool hasHistoricalUsage;
  final bool canDelete;
  final bool canDisable;

  const AdminServiceModel({
    required this.serviceID,
    required this.serviceName,
    required this.category,
    required this.type,
    required this.price,
    required this.pricingModel,
    required this.deliveryModel,
    required this.isAvailable,
    required this.isDeleted,
    required this.linkedAgentCount,
    required this.activeAgentCount,
    required this.hasHistoricalUsage,
    required this.canDelete,
    required this.canDisable,
  });

  factory AdminServiceModel.fromJson(Map<String, dynamic> json) {
    return AdminServiceModel(
      serviceID: _readInt(json, ['serviceID', 'serviceId', 'ServiceID']),
      serviceName:
          _readString(json, ['serviceName', 'ServiceName'], fallback: ''),
      category: _readInt(json, ['category', 'Category']),
      type: _readInt(json, ['type', 'Type']),
      price: _readDouble(json, ['price', 'Price']),
      pricingModel: _readInt(json, ['pricingModel', 'PricingModel']),
      deliveryModel: _readInt(json, ['deliveryModel', 'DeliveryModel']),
      isAvailable: _readBool(json, ['isAvailable', 'IsAvailable']),
      isDeleted: _readBool(json, ['isDeleted', 'IsDeleted']),
      linkedAgentCount:
          _readInt(json, ['linkedAgentCount', 'LinkedAgentCount']),
      activeAgentCount:
          _readInt(json, ['activeAgentCount', 'ActiveAgentCount']),
      hasHistoricalUsage:
          _readBool(json, ['hasHistoricalUsage', 'HasHistoricalUsage']),
      canDelete: _readBool(json, ['canDelete', 'CanDelete']),
      canDisable: _readBool(json, ['canDisable', 'CanDisable']),
    );
  }

  static int _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static double _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is double) return value;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  static bool _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is num) return value != 0;
    }
    return false;
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }
}
