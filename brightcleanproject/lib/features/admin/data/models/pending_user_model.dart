class PendingUserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? phoneNo;
  final String? businessName;
  final String? commercialRegister;
  final String? nationalIdNumber;
  final String? vehicleType;
  final String? plateNumber;
  final List<UserDocumentModel> documents;

  PendingUserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.phoneNo,
    this.businessName,
    this.commercialRegister,
    this.nationalIdNumber,
    this.vehicleType,
    this.plateNumber,
    this.documents = const [],
  });

  factory PendingUserModel.fromJson(Map<String, dynamic> json) {
    // Safe parsing of id supporting different possible casings from ASP.NET Core
    final rawId = json['id'] ?? json['userID'] ?? json['userId'];
    int? parsedId;
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId is String) {
      parsedId = int.tryParse(rawId);
    }
    if (parsedId == null || parsedId <= 0) {
      throw const FormatException('Invalid or missing userID in PendingUserModel');
    }

    // Safe role parsing (handling numeric enum representation or string)
    final rawRole = json['role'];
    String parsedRole = '';
    if (rawRole is String) {
      parsedRole = rawRole;
    } else if (rawRole is int) {
      switch (rawRole) {
        case 0:
          parsedRole = 'Client';
          break;
        case 1:
          parsedRole = 'DeliveryStaff';
          break;
        case 2:
          parsedRole = 'LaundryAgent';
          break;
        case 3:
          parsedRole = 'Admin';
          break;
        default:
          parsedRole = 'Client';
      }
    }

    final rawDocuments = json['documents'] ?? json['Documents'];
    final documents = rawDocuments is List
        ? rawDocuments
            .whereType<Map<String, dynamic>>()
            .map(UserDocumentModel.fromJson)
            .toList()
        : <UserDocumentModel>[];

    return PendingUserModel(
      id: parsedId,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: parsedRole,
      phoneNo: json['phoneNo'] as String? ?? json['phone'] as String?,
      businessName: json['businessName'] as String?,
      commercialRegister: json['commercialRegister'] as String?,
      nationalIdNumber: json['nationalIDNumber'] as String? ??
          json['nationalIdNumber'] as String?,
      vehicleType: json['vehicleType']?.toString(),
      plateNumber: json['plateNumber'] as String?,
      documents: documents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'phoneNo': phoneNo,
      'businessName': businessName,
      'commercialRegister': commercialRegister,
      'nationalIdNumber': nationalIdNumber,
      'vehicleType': vehicleType,
      'plateNumber': plateNumber,
      'documents': documents.map((document) => document.toJson()).toList(),
    };
  }
}

class UserDocumentModel {
  final int documentId;
  final String type;
  final String fileUrl;
  final String? originalFileName;
  final String? contentType;
  final int? fileSizeBytes;
  final String reviewStatus;

  const UserDocumentModel({
    required this.documentId,
    required this.type,
    required this.fileUrl,
    this.originalFileName,
    this.contentType,
    this.fileSizeBytes,
    required this.reviewStatus,
  });

  factory UserDocumentModel.fromJson(Map<String, dynamic> json) {
    return UserDocumentModel(
      documentId: json['documentID'] as int? ??
          json['documentId'] as int? ??
          json['DocumentID'] as int? ??
          0,
      type: json['type']?.toString() ?? json['Type']?.toString() ?? '',
      fileUrl: json['fileURL'] as String? ??
          json['fileUrl'] as String? ??
          json['FileURL'] as String? ??
          '',
      originalFileName: json['originalFileName'] as String? ??
          json['OriginalFileName'] as String?,
      contentType: json['contentType'] as String? ?? json['ContentType'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as int? ?? json['FileSizeBytes'] as int?,
      reviewStatus: json['reviewStatus']?.toString() ??
          json['ReviewStatus']?.toString() ??
          'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'type': type,
      'fileUrl': fileUrl,
      'originalFileName': originalFileName,
      'contentType': contentType,
      'fileSizeBytes': fileSizeBytes,
      'reviewStatus': reviewStatus,
    };
  }
}
