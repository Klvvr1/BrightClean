class BookingModel {
  final int bookingID;
  final int clientID;
  final int laundryAgentID;
  final int addressID;
  final int? offerID;
  final int status;
  final double? finalTotal;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? scheduledAt;
  final String? specialInstructions;
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

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'] ?? json['CreatedAt'];
    DateTime? parsedCreatedAt;
    if (rawCreatedAt != null && rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    }
    if (parsedCreatedAt == null) {
      throw const FormatException('Invalid or missing createdAt in BookingModel');
    }

    final rawStatus = json['status'] ?? json['Status'];
    int parsedStatus = 0;
    if (rawStatus is int) {
      parsedStatus = rawStatus;
    } else if (rawStatus is String) {
      switch (rawStatus.toLowerCase()) {
        case 'draft':
          parsedStatus = 0;
          break;
        case 'pending':
          parsedStatus = 1;
          break;
        case 'accepted':
          parsedStatus = 2;
          break;
        case 'inprogress':
          parsedStatus = 3;
          break;
        case 'ready':
          parsedStatus = 4;
          break;
        case 'completed':
          parsedStatus = 5;
          break;
        case 'cancelled':
          parsedStatus = 6;
          break;
      }
    }

    final rawItems = json['bookingItems'] ?? json['BookingItems'] ?? [];
    List<BookingItemModel> itemsList = [];
    if (rawItems is List) {
      itemsList = rawItems.map((item) => BookingItemModel.fromJson(item as Map<String, dynamic>)).toList();
    }

    return BookingModel(
      bookingID: json['bookingID'] as int? ?? json['bookingId'] as int? ?? json['BookingID'] as int? ?? 0,
      clientID: json['clientID'] as int? ?? json['clientId'] as int? ?? json['ClientID'] as int? ?? 0,
      laundryAgentID: json['laundryAgentID'] as int? ?? json['laundryAgentId'] as int? ?? json['LaundryAgentID'] as int? ?? 0,
      addressID: json['addressID'] as int? ?? json['addressId'] as int? ?? json['AddressID'] as int? ?? 0,
      offerID: json['offerID'] as int? ?? json['offerId'] as int? ?? json['OfferID'] as int?,
      status: parsedStatus,
      finalTotal: (json['finalTotal'] ?? json['FinalTotal'] as num?)?.toDouble(),
      createdAt: parsedCreatedAt,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : json['ExpiresAt'] != null
              ? DateTime.tryParse(json['ExpiresAt'] as String)
              : null,
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'] as String)
          : json['ScheduledAt'] != null
              ? DateTime.tryParse(json['ScheduledAt'] as String)
              : null,
      specialInstructions: json['specialInstructions'] as String? ?? json['SpecialInstructions'] as String?,
      bookingItems: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingID': bookingID,
      'clientID': clientID,
      'laundryAgentID': laundryAgentID,
      'addressID': addressID,
      'offerID': offerID,
      'status': status,
      'finalTotal': finalTotal,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'scheduledAt': scheduledAt?.toIso8601String(),
      'specialInstructions': specialInstructions,
      'bookingItems': bookingItems.map((item) => item.toJson()).toList(),
    };
  }
}

class BookingItemModel {
  final int bookingItemID;
  final int bookingID;
  final int serviceID;
  final int quantity;
  final double unitPriceAtTimeOfBooking;
  final ServiceCatalogItemModel? serviceCatalogItem;

  BookingItemModel({
    required this.bookingItemID,
    required this.bookingID,
    required this.serviceID,
    required this.quantity,
    required this.unitPriceAtTimeOfBooking,
    this.serviceCatalogItem,
  });

  factory BookingItemModel.fromJson(Map<String, dynamic> json) {
    return BookingItemModel(
      bookingItemID: json['bookingItemID'] as int? ?? json['bookingItemId'] as int? ?? json['BookingItemID'] as int? ?? 0,
      bookingID: json['bookingID'] as int? ?? json['bookingId'] as int? ?? json['BookingID'] as int? ?? 0,
      serviceID: json['serviceID'] as int? ?? json['serviceId'] as int? ?? json['ServiceID'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? json['Quantity'] as int? ?? 0,
      unitPriceAtTimeOfBooking: (json['unitPriceAtTimeOfBooking'] ?? json['UnitPriceAtTimeOfBooking'] as num?)?.toDouble() ?? 0.0,
      serviceCatalogItem: json['serviceCatalogItem'] != null
          ? ServiceCatalogItemModel.fromJson(json['serviceCatalogItem'] as Map<String, dynamic>)
          : json['ServiceCatalogItem'] != null
              ? ServiceCatalogItemModel.fromJson(json['ServiceCatalogItem'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingItemID': bookingItemID,
      'bookingID': bookingID,
      'serviceID': serviceID,
      'quantity': quantity,
      'unitPriceAtTimeOfBooking': unitPriceAtTimeOfBooking,
      'serviceCatalogItem': serviceCatalogItem?.toJson(),
    };
  }
}

class ServiceCatalogItemModel {
  final int serviceID;
  final String serviceName;
  final int category;
  final int type;
  final double price;
  final int pricingModel;
  final int deliveryModel;
  final bool isAvailable;
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

  factory ServiceCatalogItemModel.fromJson(Map<String, dynamic> json) {
    // 1. ServiceCategory
    final rawCategory = json['category'] ?? json['Category'];
    int parsedCategory = 0;
    if (rawCategory is int) {
      parsedCategory = rawCategory;
    } else if (rawCategory is String) {
      switch (rawCategory.toLowerCase()) {
        case 'laundry':
          parsedCategory = 0;
          break;
        case 'homewovens':
          parsedCategory = 1;
          break;
        case 'homeservices':
          parsedCategory = 2;
          break;
        case 'vehiclewash':
          parsedCategory = 3;
          break;
      }
    }

    // 2. ServiceType
    final rawType = json['type'] ?? json['Type'];
    int parsedType = 0;
    if (rawType is int) {
      parsedType = rawType;
    } else if (rawType is String) {
      switch (rawType.toLowerCase()) {
        case 'washandiron':
          parsedType = 0;
          break;
        case 'dryclean':
          parsedType = 1;
          break;
        case 'irononly':
          parsedType = 2;
          break;
        case 'curtains':
          parsedType = 3;
          break;
        case 'bedsheets':
          parsedType = 4;
          break;
        case 'blankets':
          parsedType = 5;
          break;
        case 'carpets':
          parsedType = 6;
          break;
        case 'homecleaning':
          parsedType = 7;
          break;
        case 'accleaning':
          parsedType = 8;
          break;
        case 'watertankcleaning':
          parsedType = 9;
          break;
        case 'solarpanelcleaning':
          parsedType = 10;
          break;
        case 'carwash':
          parsedType = 11;
          break;
        case 'motorcyclewash':
          parsedType = 12;
          break;
      }
    }

    // 3. PricingModel
    final rawPricing = json['pricingModel'] ?? json['PricingModel'];
    int parsedPricing = 0;
    if (rawPricing is int) {
      parsedPricing = rawPricing;
    } else if (rawPricing is String) {
      switch (rawPricing.toLowerCase()) {
        case 'peritem':
          parsedPricing = 0;
          break;
        case 'flatfee':
          parsedPricing = 1;
          break;
      }
    }

    // 4. DeliveryModel
    final rawDelivery = json['deliveryModel'] ?? json['DeliveryModel'];
    int parsedDelivery = 0;
    if (rawDelivery is int) {
      parsedDelivery = rawDelivery;
    } else if (rawDelivery is String) {
      switch (rawDelivery.toLowerCase()) {
        case 'twostage':
          parsedDelivery = 0;
          break;
        case 'techniciandispatch':
          parsedDelivery = 1;
          break;
      }
    }

    return ServiceCatalogItemModel(
      serviceID: json['serviceID'] as int? ?? json['serviceId'] as int? ?? json['ServiceID'] as int? ?? 0,
      serviceName: json['serviceName'] as String? ?? json['ServiceName'] as String? ?? '',
      category: parsedCategory,
      type: parsedType,
      price: (json['price'] ?? json['Price'] as num?)?.toDouble() ?? 0.0,
      pricingModel: parsedPricing,
      deliveryModel: parsedDelivery,
      isAvailable: json['isAvailable'] as bool? ?? json['IsAvailable'] as bool? ?? false,
      adminID: json['adminID'] as int? ?? json['adminId'] as int? ?? json['AdminID'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceID': serviceID,
      'serviceName': serviceName,
      'category': category,
      'type': type,
      'price': price,
      'pricingModel': pricingModel,
      'deliveryModel': deliveryModel,
      'isAvailable': isAvailable,
      'adminID': adminID,
    };
  }
}
