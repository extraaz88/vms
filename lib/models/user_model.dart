class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? title;
  final String? phone;
  final String? avatar;
  final DateTime? lastLoginAt;
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.title,
    this.phone,
    this.avatar,
    this.lastLoginAt,
    this.isActive = true,
  });

  static const Set<String> _developerAccessRoles = {
    'flutter developer',
    'branch director',
    'ux designer',
    'backend developer',
    'aws cloud engineer',
    'frontend developer',
  };

  // Helper method to check if user should get developer-level access (Flutter or similar roles)
  bool get isFlutterDeveloper {
    final roleLower = role.toLowerCase().trim();
    final titleLower = title?.toLowerCase().trim();
    return _developerAccessRoles.contains(roleLower) ||
        (titleLower != null && _developerAccessRoles.contains(titleLower));
  }
  
  // Helper method to check if user is Sales person
  bool get isSalesPerson => 
      title?.toLowerCase().contains('sales') == true || 
      role.toLowerCase().contains('sales') == true ||
      title?.toLowerCase().contains('field') == true ||
      role.toLowerCase().contains('field') == true;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? json['type'] ?? 'employee',
      title: json['title'],
      phone: json['phone'],
      avatar: json['avatar'],
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'])
          : null,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'title': title,
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
    String? title,
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
      title: title ?? this.title,
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
