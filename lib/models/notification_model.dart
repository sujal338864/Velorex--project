class UserNotification {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime sendDate;

  UserNotification({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.sendDate,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['NotificationID'],
      title: json['Title'] ?? '',
      description: json['Description'] ?? '',
      imageUrl: json['ImageUrl'],
      sendDate: DateTime.parse(json['SendDate']),
    );
  }
}
