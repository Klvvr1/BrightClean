class LoginResponseModel {
  final String token;
  final int userId;
  final String role;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNo;

  LoginResponseModel({
    required this.token,
    required this.userId,
    required this.role,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNo = '',
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String? ?? '';
    if (token.isEmpty) {
      throw const FormatException('Invalid or missing token in LoginResponseModel');
    }

    final rawUserId = json['userId'] ?? json['userID'];
    int? parsedUserId;
    if (rawUserId is int) {
      parsedUserId = rawUserId;
    } else if (rawUserId is String) {
      parsedUserId = int.tryParse(rawUserId);
    }

    if (parsedUserId == null || parsedUserId <= 0) {
      throw const FormatException('Invalid or missing userId in LoginResponseModel');
    }

    return LoginResponseModel(
      token: token,
      userId: parsedUserId,
      role: json['role'] as String? ?? 'Customer',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phoneNo: json['phoneNo'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'userId': userId,
      'role': role,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNo': phoneNo,
    };
  }
}
