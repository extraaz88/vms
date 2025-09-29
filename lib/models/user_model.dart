class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? avatar;
  final DateTime? lastLoginAt;
  final bool isActive;
  
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatar,
    this.lastLoginAt,
    this.isActive = true,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'employee',
      phone: json['phone'],
      avatar: json['avatar'],
      lastLoginAt: json['last_login_at'] != null 
          ? DateTime.parse(json['last_login_at'])
          : null,
      isActive: json['is_active'] ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'avatar': avatar,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_active': isActive,
    };
  }
  
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? avatar,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }
  
  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, role: $role)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}
