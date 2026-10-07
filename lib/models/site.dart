class Site {
  final int id;
  final String code;
  final String name;
  final String? clientName;
  final String? workDate;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String status;
  final String? description;

  const Site({
    required this.id,
    required this.code,
    required this.name,
    this.clientName,
    this.workDate,
    this.startTime,
    this.endTime,
    this.location,
    required this.status,
    this.description,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      clientName: json['client_name']?.toString(),
      workDate: json['work_date']?.toString(),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      location: json['location']?.toString(),
      status: json['status']?.toString() ?? 'active',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'client_name': clientName,
    'work_date': workDate,
    'start_time': startTime,
    'end_time': endTime,
    'location': location,
    'status': status,
    'description': description,
  };
}
