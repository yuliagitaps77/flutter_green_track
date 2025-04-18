import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';

// class UserModel {
//   final String id;
//   final String name;
//   final String email;
//   final UserRole role;
//   final String photoUrl;

//   UserModel({
//     required this.id,
//     required this.name,
//     required this.email,
//     required this.role,
//     required this.photoUrl,
//   });

//   // Convert Firestore document to UserModel
//   factory UserModel.fromFirestore(DocumentSnapshot doc) {
//     Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//     return UserModel(
//       id: doc.id,
//       name: data['nama_lengkap'] ?? '',
//       email: data['email'] ?? '',
//       role: data['role']?.contains('admin_penyemaian') == true
//           ? UserRole.adminPenyemaian
//           : UserRole.adminTPK,
//       photoUrl: data['photo_url'] ?? '',
//     );
//   }

//   // Convert UserModel to JSON for SharedPreferences
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'email': email,
//       'role':
//           role == UserRole.adminPenyemaian ? 'admin_penyemaian' : 'admin_tpk',
//       'photoUrl': photoUrl,
//     };
//   }

//   // Create UserModel from JSON (SharedPreferences)
//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     return UserModel(
//       id: json['id'] ?? '',
//       name: json['name'] ?? '',
//       email: json['email'] ?? '',
//       role: json['role'] == 'admin_penyemaian'
//           ? UserRole.adminPenyemaian
//           : UserRole.adminTPK,
//       photoUrl: json['photoUrl'] ?? '',
//     );
//   }
// }
