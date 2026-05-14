class UserProfile {
  final String name;
  final String phone;
  final String walletBalance;
  final String? imagePath;

  const UserProfile({
    required this.name,
    required this.phone,
    required this.walletBalance,
    this.imagePath,
  });
}
