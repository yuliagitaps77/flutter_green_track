// Define user roles for the app
enum UserRole {
  adminTPK,
  adminPenyemaian,
}

// Convert UserRole enum to string for storage
String userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.adminTPK:
      return 'adminTPK';
    case UserRole.adminPenyemaian:
      return 'adminPenyemaian';
    default:
      return 'adminTPK'; // Default role
  }
}

// Convert string back to UserRole enum
UserRole stringToUserRole(String roleStr) {
  switch (roleStr) {
    case 'adminPenyemaian':
      return UserRole.adminPenyemaian;
    case 'adminTPK':
    default:
      return UserRole.adminTPK;
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String photoUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.photoUrl,
  });

  // Convert user model to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': userRoleToString(role),
      'photoUrl': photoUrl,
    };
  }

  // Create user model from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: stringToUserRole(json['role'] ?? 'adminTPK'),
      photoUrl: json['photoUrl'] ?? '',
    );
  }

  // Create a copy of the user with some updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? photoUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
