class LoginResponseModel {
  final String token;
  final int userId;
  final String role;
  final String email;
  final String firstName;
  final String lastName;

  LoginResponseModel({
    required this.token,
    required this.userId,
    required this.role,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    // Safe parsing of userId from String or Int
    final rawUserId = json['userId'];
    int parsedUserId = 0;
    if (rawUserId is int) {
      parsedUserId = rawUserId;
    } else if (rawUserId is String) {
      parsedUserId = int.tryParse(rawUserId) ?? 0;
    }

    return LoginResponseModel(
      token: json['token'] as String? ?? '',
      userId: parsedUserId,
      role: json['role'] as String? ?? 'Customer',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
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
    };
  }
}
