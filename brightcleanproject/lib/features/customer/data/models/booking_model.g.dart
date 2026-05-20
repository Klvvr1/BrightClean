// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingModel _$BookingModelFromJson(Map<String, dynamic> json) => BookingModel(
      bookingID: (json['bookingID'] as num).toInt(),
      clientID: (json['clientID'] as num).toInt(),
      laundryAgentID: (json['laundryAgentID'] as num).toInt(),
      addressID: (json['addressID'] as num).toInt(),
      offerID: (json['offerID'] as num?)?.toInt(),
      status: (json['status'] as num).toInt(),
      finalTotal: (json['finalTotal'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      scheduledAt: json['scheduledAt'] == null
          ? null
          : DateTime.parse(json['scheduledAt'] as String),
      specialInstructions: json['specialInstructions'] as String?,
      bookingItems: (json['bookingItems'] as List<dynamic>)
          .map((e) => BookingItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BookingModelToJson(BookingModel instance) =>
    <String, dynamic>{
      'bookingID': instance.bookingID,
      'clientID': instance.clientID,
      'laundryAgentID': instance.laundryAgentID,
      'addressID': instance.addressID,
      'offerID': instance.offerID,
      'status': instance.status,
      'finalTotal': instance.finalTotal,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'scheduledAt': instance.scheduledAt?.toIso8601String(),
      'specialInstructions': instance.specialInstructions,
      'bookingItems': instance.bookingItems.map((e) => e.toJson()).toList(),
    };

BookingItemModel _$BookingItemModelFromJson(Map<String, dynamic> json) =>
    BookingItemModel(
      bookingItemID: (json['bookingItemID'] as num).toInt(),
      bookingID: (json['bookingID'] as num).toInt(),
      serviceID: (json['serviceID'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      unitPriceAtTimeOfBooking:
          (json['unitPriceAtTimeOfBooking'] as num).toDouble(),
      serviceCatalogItem: json['serviceCatalogItem'] == null
          ? null
          : ServiceCatalogItemModel.fromJson(
              json['serviceCatalogItem'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BookingItemModelToJson(BookingItemModel instance) =>
    <String, dynamic>{
      'bookingItemID': instance.bookingItemID,
      'bookingID': instance.bookingID,
      'serviceID': instance.serviceID,
      'quantity': instance.quantity,
      'unitPriceAtTimeOfBooking': instance.unitPriceAtTimeOfBooking,
      'serviceCatalogItem': instance.serviceCatalogItem?.toJson(),
    };

ServiceCatalogItemModel _$ServiceCatalogItemModelFromJson(
        Map<String, dynamic> json) =>
    ServiceCatalogItemModel(
      serviceID: (json['serviceID'] as num).toInt(),
      serviceName: json['serviceName'] as String,
      category: (json['category'] as num).toInt(),
      type: (json['type'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      pricingModel: (json['pricingModel'] as num).toInt(),
      deliveryModel: (json['deliveryModel'] as num).toInt(),
      isAvailable: json['isAvailable'] as bool,
      adminID: (json['adminID'] as num).toInt(),
    );

Map<String, dynamic> _$ServiceCatalogItemModelToJson(
        ServiceCatalogItemModel instance) =>
    <String, dynamic>{
      'serviceID': instance.serviceID,
      'serviceName': instance.serviceName,
      'category': instance.category,
      'type': instance.type,
      'price': instance.price,
      'pricingModel': instance.pricingModel,
      'deliveryModel': instance.deliveryModel,
      'isAvailable': instance.isAvailable,
      'adminID': instance.adminID,
    };
