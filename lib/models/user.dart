class User {
  final int id;
  final String fullName;
  final String username;
  final String email;
  final String role;
  final String? phone;
  final String? specialization;

  const User({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.role,
    this.phone,
    this.specialization,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      fullName: json['full_name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone']?.toString(),
      specialization: json['specialization']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'username': username,
    'email': email,
    'role': role,
    'phone': phone,
    'specialization': specialization,
  };
}
