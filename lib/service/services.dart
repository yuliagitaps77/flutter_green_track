// 1. Tambahkan dependencies berikut di pubspec.yaml:
/*
dependencies:
  flutter:
    sdk: flutter
  get: ^4.6.5
  firebase_core: ^2.15.1
  firebase_auth: ^4.9.0
  cloud_firestore: ^4.9.1
  shared_preferences: ^2.2.1
  fl_chart: ^0.63.0
*/

// 2. File models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// 3. File services/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';
import 'package:flutter_green_track/data/models/user_model.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/model/model_dashboard_tpk.dart';
import 'package:flutter_green_track/fitur/navigation/navigation_page.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth methods
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentFirebaseUser() {
    return _auth.currentUser;
  }

  // Firestore methods
  Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('akun').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // SharedPreferences methods
  Future<void> saveUserLocally(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  Future<UserModel?> getLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return UserModel.fromJson(jsonDecode(userData));
    }
    return null;
  }

  Future<void> removeLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }

  // Dashboard data methods
  Future<Map<String, dynamic>> getPenyemaianDashboardData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('dashboard_informasi_admin_penyemaian')
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Error getting dashboard data: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivities(String userId,
      {int limit = 5}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('aktivitas')
          .where('id_user', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting recent activities: $e');
      return [];
    }
  }
}

enum LoginStatus { initial, loading, success, failure }




// // 6. File main.dart (initialization)
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'controllers/authentication_controller.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
  
//   // Register global controllers
//   Get.put(AuthenticationController());
  
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'Aplikasi Bibit',
//       theme: ThemeData(
//         primarySwatch: Colors.green,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       initialRoute: '/login',
//       getPages: [
//         GetPage(name: '/login', page: () => LoginScreen()),
//         // Add other pages here
//       ],
//     );
//   }
// }