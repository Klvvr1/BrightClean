class CustomerAddressModel {
  final int addressID;
  final String area;
  final String street;
  final double latitude;
  final double longitude;

  const CustomerAddressModel({
    required this.addressID,
    required this.area,
    required this.street,
    required this.latitude,
    required this.longitude,
  });

  factory CustomerAddressModel.fromJson(Map<String, dynamic> json) {
    return CustomerAddressModel(
      addressID: _readInt(
              json['addressID'] ?? json['addressId'] ?? json['AddressID']) ??
          0,
      area: (json['area'] ?? json['Area'] ?? '').toString(),
      street: (json['street'] ?? json['Street'] ?? '').toString(),
      latitude: _readDouble(json['latitude'] ?? json['Latitude']),
      longitude: _readDouble(json['longitude'] ?? json['Longitude']),
    );
  }

  String get label {
    if (area.trim() == street.trim()) return area.trim();
    return '${area.trim()}, ${street.trim()}';
  }

  bool get isValid {
    return addressID > 0 &&
        area.trim().isNotEmpty &&
        street.trim().isNotEmpty &&
        !(latitude == 0.0 && longitude == 0.0);
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
