class NotificationItem {
  final int id;
  final String title;
  final String message;
  final String type;
  final String? link;
  final int isRead;
  final String? createdAt;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.link,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      link: json['link']?.toString(),
      isRead: json['is_read'] is int ? json['is_read'] : int.tryParse('${json['is_read']}') ?? 0,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type,
    'link': link,
    'is_read': isRead,
    'created_at': createdAt,
  };
}
