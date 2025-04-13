import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLogin;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.photoUrl,
    required this.createdAt,
    required this.lastLogin,
  });

  // Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] == 'adminPenyemaian'
          ? UserRole.adminPenyemaian
          : UserRole.adminTPK,
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role == UserRole.adminPenyemaian ? 'adminPenyemaian' : 'adminTPK',
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? name,
    String? photoUrl,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: this.id,
      email: this.email,
      name: name ?? this.name,
      role: this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
