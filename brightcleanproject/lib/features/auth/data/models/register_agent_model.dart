class RegisterAgentModel {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phoneNo;
  final String dateOfBirth;
  final String fatherName;
  final String grandfatherName;
  final String nationalIdNumber;
  final String businessName;
  final String commercialRegister;
  final String bankAcc;
  final String area;
  final String street;
  final double latitude;
  final double longitude;
  final List<int> selectedServiceCategories;

  RegisterAgentModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phoneNo,
    required this.dateOfBirth,
    required this.fatherName,
    required this.grandfatherName,
    required this.nationalIdNumber,
    required this.businessName,
    required this.commercialRegister,
    required this.bankAcc,
    required this.area,
    required this.street,
    required this.latitude,
    required this.longitude,
    required this.selectedServiceCategories,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'phoneNo': phoneNo,
      'dateOfBirth': dateOfBirth,
      'fatherName': fatherName,
      'grandfatherName': grandfatherName,
      'nationalIdNumber': nationalIdNumber,
      'businessName': businessName,
      'commercialRegister': commercialRegister,
      'bankAcc': bankAcc,
      'area': area,
      'street': street,
      'latitude': latitude,
      'longitude': longitude,
      'selectedServiceCategories': selectedServiceCategories.join(','),
    };
  }
}
