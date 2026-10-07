class TaskItem {
  final int id;
  final int siteId;
  final String siteName;
  final String title;
  final String? description;
  final int? assignedTo;
  final int isBroadcast;
  final String priority;
  final String status;
  final int progress;
  final String? createdAt;
  final String? updatedAt;

  const TaskItem({
    required this.id,
    required this.siteId,
    required this.siteName,
    required this.title,
    this.description,
    this.assignedTo,
    this.isBroadcast = 0,
    required this.priority,
    required this.status,
    required this.progress,
    this.createdAt,
    this.updatedAt,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      siteId: json['site_id'] is int ? json['site_id'] : int.tryParse('${json['site_id']}') ?? 0,
      siteName: json['site_name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      assignedTo: json['assigned_to'] is int ? json['assigned_to'] : int.tryParse('${json['assigned_to']}'),
      isBroadcast: json['is_broadcast'] is int ? json['is_broadcast'] : int.tryParse('${json['is_broadcast']}') ?? 0,
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'pending',
      progress: json['progress'] is int ? json['progress'] : int.tryParse('${json['progress']}') ?? 0,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'site_id': siteId,
    'site_name': siteName,
    'title': title,
    'description': description,
    'assigned_to': assignedTo,
    'is_broadcast': isBroadcast,
    'priority': priority,
    'status': status,
    'progress': progress,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}
