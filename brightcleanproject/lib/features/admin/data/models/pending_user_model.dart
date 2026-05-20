class PendingUserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? phoneNo;
  final String? businessName;
  final String? commercialRegister;

  PendingUserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.phoneNo,
    this.businessName,
    this.commercialRegister,
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

    return PendingUserModel(
      id: parsedId,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: parsedRole,
      phoneNo: json['phoneNo'] as String? ?? json['phone'] as String?,
      businessName: json['businessName'] as String?,
      commercialRegister: json['commercialRegister'] as String?,
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
    };
  }
}
