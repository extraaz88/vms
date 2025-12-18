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
  // Sales person tab hi hoga jab type explicitly 'sales' ho
  // Agar type null, empty, 'user', 'employee', ya kuch bhi aur hai to false (Developer dashboard)
  bool get isSalesPerson {
    // Agar role empty hai ya null hai to definitely Sales person nahi hai
    if (role.isEmpty || role.trim().isEmpty) {
      return false;
    }
    
    final roleLower = role.toLowerCase().trim();
    
    // Sirf type 'sales' ho to Sales person
    // Type null, empty, 'user', 'employee', ya kuch bhi aur ho to false (Developer dashboard)
    return roleLower == 'sales';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // API se 'type' field aata hai (e.g., "User", "sales", null, etc.)
    // 'type' ko 'role' mein map karte hain for consistency
    // Null check properly karte hain
    final typeValue = json['type'];
    final roleValue = json['role'];
    
    // Agar type null hai ya empty hai, to empty string use karte hain
    // Sirf explicitly "sales" ho to Sales person, warna Developer
    String finalRole = '';
    if (typeValue != null && typeValue.toString().trim().isNotEmpty) {
      finalRole = typeValue.toString().trim();
    } else if (roleValue != null && roleValue.toString().trim().isNotEmpty) {
      finalRole = roleValue.toString().trim();
    }
    
    return User(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: finalRole, // Type ko role mein map karte hain
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
