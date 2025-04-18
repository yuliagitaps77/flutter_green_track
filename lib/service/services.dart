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
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';
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
  // Tambahkan metode ini ke FirebaseService

// Menghitung data dashboard langsung dari koleksi bibit
  Future<Map<String, dynamic>> calculatePenyemaianDashboardData(
      String userId) async {
    try {
      // Ambil semua bibit yang terkait dengan user ini
      QuerySnapshot bibitSnapshot = await _firestore
          .collection('bibit')
          .where('id_user', isEqualTo: userId)
          .get();

      // Inisialisasi counter
      int totalBibit = bibitSnapshot.docs.length;
      int bibitSiapTanam = 0;
      int butuhPerhatian = 0;

      // Hitung berdasarkan kondisi
      for (var doc in bibitSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String kondisi = data['kondisi'] as String? ?? '';

        if (kondisi == 'Siap Tanam') {
          bibitSiapTanam++;
        } else if (kondisi == 'Butuh Perawatan' || kondisi == 'Kritis') {
          butuhPerhatian++;
        }
      }

      // Hitung bibit yang dipindai (menggunakan collection group query)
      int totalBibitDipindai = await _firestore
          .collectionGroup('pengisian_history')
          .where('id_user', isEqualTo: userId)
          .get()
          .then((snapshot) => snapshot.docs.length);

      // Ambil data sebelumnya (1 bulan lalu) untuk perhitungan pertumbuhan
      // Gunakan timestamp dari dokumen bibit
      int previousTotalBibit = 0;
      final oneMonthAgo = DateTime.now().subtract(Duration(days: 30));

      for (var doc in bibitSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        Timestamp? createdAt = data['created_at'] as Timestamp?;

        if (createdAt != null && createdAt.toDate().isAfter(oneMonthAgo)) {
          previousTotalBibit++;
        }
      }

      // Hitung previous total (bibit yang ada sebelum 1 bulan lalu)
      previousTotalBibit = totalBibit - previousTotalBibit;
      if (previousTotalBibit < 0) previousTotalBibit = 0;

      return {
        'total_bibit': totalBibit,
        'bibit_siap_tanam': bibitSiapTanam,
        'butuh_perhatian': butuhPerhatian,
        'total_bibit_dipindai': totalBibitDipindai,
        'previous_total_bibit': previousTotalBibit,
      };
    } catch (e) {
      print('Error calculating penyemaian dashboard data: $e');
      return {};
    }
  }

// Menghitung data dashboard langsung dari koleksi kayu
  Future<Map<String, dynamic>> calculateTPKDashboardData(String userId) async {
    try {
      // Ambil semua kayu yang terkait dengan user ini
      QuerySnapshot kayuSnapshot = await _firestore
          .collection('kayu')
          .where('id_user', isEqualTo: userId)
          .get();

      // Inisialisasi counter
      int totalKayu = kayuSnapshot.docs.length;

      // Hitung kayu yang dipindai
      int totalKayuDipindai = await _firestore
          .collectionGroup('riwayat_scan')
          .where('id_user', isEqualTo: userId)
          .get()
          .then((snapshot) => snapshot.docs.length);

      // Hitung jumlah batch unik
      Set<String> uniqueBatches = {};
      for (var doc in kayuSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String batch = data['batch_panen'] as String? ?? '';
        if (batch.isNotEmpty) {
          uniqueBatches.add(batch);
        }
      }

      int totalBatch = uniqueBatches.length;

      return {
        'total_kayu': totalKayu,
        'total_kayu_dipindai': totalKayuDipindai,
        'total_batch': totalBatch,
      };
    } catch (e) {
      print('Error calculating TPK dashboard data: $e');
      return {};
    }
  }

// Update getPenyemaianDashboardData untuk menggunakan fungsi perhitungan langsung
  Future<Map<String, dynamic>> getPenyemaianDashboardData(String userId) async {
    try {
      // Coba ambil dari cache dulu (opsional, untuk performa)
      final prefs = await SharedPreferences.getInstance();
      final String cacheKey = 'dashboard_penyemaian_$userId';
      final String? cachedData = prefs.getString(cacheKey);
      final int cacheExpiry = prefs.getInt('${cacheKey}_expiry') ?? 0;

      // Jika cache masih valid (tidak lebih dari 5 menit), gunakan cache
      if (cachedData != null &&
          cacheExpiry > DateTime.now().millisecondsSinceEpoch) {
        return jsonDecode(cachedData);
      }

      // Hitung data dashboard langsung dari koleksi bibit
      final dashboardData = await calculatePenyemaianDashboardData(userId);

      // Simpan hasil ke cache untuk 5 menit
      await prefs.setString(cacheKey, jsonEncode(dashboardData));
      await prefs.setInt('${cacheKey}_expiry',
          DateTime.now().add(Duration(minutes: 5)).millisecondsSinceEpoch);

      return dashboardData;
    } catch (e) {
      print('Error getting penyemaian dashboard data: $e');
      return {};
    }
  }

// Buat fungsi TPK dashboard
  Future<Map<String, dynamic>> getTPKDashboardData(String userId) async {
    try {
      // Coba ambil dari cache dulu (opsional, untuk performa)
      final prefs = await SharedPreferences.getInstance();
      final String cacheKey = 'dashboard_tpk_$userId';
      final String? cachedData = prefs.getString(cacheKey);
      final int cacheExpiry = prefs.getInt('${cacheKey}_expiry') ?? 0;

      // Jika cache masih valid (tidak lebih dari 5 menit), gunakan cache
      if (cachedData != null &&
          cacheExpiry > DateTime.now().millisecondsSinceEpoch) {
        return jsonDecode(cachedData);
      }

      // Hitung data dashboard langsung dari koleksi kayu
      final dashboardData = await calculateTPKDashboardData(userId);

      // Simpan hasil ke cache untuk 5 menit
      await prefs.setString(cacheKey, jsonEncode(dashboardData));
      await prefs.setInt('${cacheKey}_expiry',
          DateTime.now().add(Duration(minutes: 5)).millisecondsSinceEpoch);

      return dashboardData;
    } catch (e) {
      print('Error getting TPK dashboard data: $e');
      return {};
    }
  }

// Fungsi helper untuk menghapus cache dashboard
  Future<void> clearDashboardCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('dashboard_penyemaian_$userId');
      await prefs.remove('dashboard_penyemaian_${userId}_expiry');
      await prefs.remove('dashboard_tpk_$userId');
      await prefs.remove('dashboard_tpk_${userId}_expiry');
    } catch (e) {
      print('Error clearing dashboard cache: $e');
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