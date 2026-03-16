class NotificationModel {
  final int? id;
  final String title;
  final String message;
  final String date;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        print('Error parsing date: $value, using now(). Error: $e');
        return DateTime.now();
      }
    }

    return NotificationModel(
      id: json['id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      date: json['date'] ?? '',
      createdAt: parseDate(json['created_at']),
      isRead: json['is_read'] == 1 || json['isRead'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'date': date,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    String? date,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
