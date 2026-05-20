import 'package:json_annotation/json_annotation.dart';

part 'booking_model.g.dart';

@JsonSerializable(explicitToJson: true)
class BookingModel {
  @JsonKey(name: 'bookingID')
  final int bookingID;

  @JsonKey(name: 'clientID')
  final int clientID;

  @JsonKey(name: 'laundryAgentID')
  final int laundryAgentID;

  @JsonKey(name: 'addressID')
  final int addressID;

  @JsonKey(name: 'offerID')
  final int? offerID;

  @JsonKey(name: 'status')
  final int status;

  @JsonKey(name: 'finalTotal')
  final double? finalTotal;

  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  @JsonKey(name: 'expiresAt')
  final DateTime? expiresAt;

  @JsonKey(name: 'scheduledAt')
  final DateTime? scheduledAt;

  @JsonKey(name: 'specialInstructions')
  final String? specialInstructions;

  @JsonKey(name: 'bookingItems')
  final List<BookingItemModel> bookingItems;

  BookingModel({
    required this.bookingID,
    required this.clientID,
    required this.laundryAgentID,
    required this.addressID,
    this.offerID,
    required this.status,
    this.finalTotal,
    required this.createdAt,
    this.expiresAt,
    this.scheduledAt,
    this.specialInstructions,
    required this.bookingItems,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) =>
      _$BookingModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookingModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BookingItemModel {
  @JsonKey(name: 'bookingItemID')
  final int bookingItemID;

  @JsonKey(name: 'bookingID')
  final int bookingID;

  @JsonKey(name: 'serviceID')
  final int serviceID;

  @JsonKey(name: 'quantity')
  final int quantity;

  @JsonKey(name: 'unitPriceAtTimeOfBooking')
  final double unitPriceAtTimeOfBooking;

  @JsonKey(name: 'serviceCatalogItem')
  final ServiceCatalogItemModel? serviceCatalogItem;

  BookingItemModel({
    required this.bookingItemID,
    required this.bookingID,
    required this.serviceID,
    required this.quantity,
    required this.unitPriceAtTimeOfBooking,
    this.serviceCatalogItem,
  });

  factory BookingItemModel.fromJson(Map<String, dynamic> json) =>
      _$BookingItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookingItemModelToJson(this);
}

@JsonSerializable()
class ServiceCatalogItemModel {
  @JsonKey(name: 'serviceID')
  final int serviceID;

  @JsonKey(name: 'serviceName')
  final String serviceName;

  @JsonKey(name: 'category')
  final int category;

  @JsonKey(name: 'type')
  final int type;

  @JsonKey(name: 'price')
  final double price;

  @JsonKey(name: 'pricingModel')
  final int pricingModel;

  @JsonKey(name: 'deliveryModel')
  final int deliveryModel;

  @JsonKey(name: 'isAvailable')
  final bool isAvailable;

  @JsonKey(name: 'adminID')
  final int adminID;

  ServiceCatalogItemModel({
    required this.serviceID,
    required this.serviceName,
    required this.category,
    required this.type,
    required this.price,
    required this.pricingModel,
    required this.deliveryModel,
    required this.isAvailable,
    required this.adminID,
  });

  factory ServiceCatalogItemModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceCatalogItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceCatalogItemModelToJson(this);
}
