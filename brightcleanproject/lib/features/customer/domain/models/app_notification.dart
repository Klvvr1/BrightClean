class AppNotification {
  final int notificationID;
  final int userID;
  final String title;
  final String message;
  final DateTime date;
  final bool isRead;

  AppNotification({
    required this.notificationID,
    required this.userID,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      notificationID: json['notificationID'] as int? ?? json['notificationId'] as int? ?? 0,
      userID: json['userID'] as int? ?? json['userId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      date: DateTime.parse(json['date'] as String? ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] as bool? ?? json['IsRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationID': notificationID,
      'userID': userID,
      'title': title,
      'message': message,
      'date': date.toIso8601String(),
      'isRead': isRead,
    };
  }
}
