class RegisterClientModel {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phoneNo;
  final String dateOfBirth;
  final String gender;
  final String area;
  final String street;
  final double latitude;
  final double longitude;

  RegisterClientModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phoneNo,
    required this.dateOfBirth,
    required this.gender,
    required this.area,
    required this.street,
    required this.latitude,
    required this.longitude,
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
      'area': area,
      'street': street,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
