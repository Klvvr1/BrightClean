class RegisterClientModel {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phoneNo;
  final String dateOfBirth;
  final String gender;

  RegisterClientModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phoneNo,
    required this.dateOfBirth,
    required this.gender,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'phoneNo': phoneNo,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
    };
  }
}
