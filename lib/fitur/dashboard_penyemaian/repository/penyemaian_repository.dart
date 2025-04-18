// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';

// import '../../dashboard_tpk/model/model_dashboard_tpk.dart';
// import '../model/model_dashboard_penyemaian.dart';
// class PenyemaianRepository {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
  
//   // Get user profile from Firestore
//   Future<UserProfileModel> getUserProfile() async {
//     try {
//       User? currentUser = _auth.currentUser;
//       if (currentUser == null) {
//         throw Exception('User not authenticated');
//       }

//       DocumentSnapshot userDoc = await _firestore
//           .collection('akun')
//           .doc(currentUser.uid)
//           .get();

//       if (!userDoc.exists) {
//         throw Exception('User profile not found');
//       }

//       Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
//       return UserProfileModel(
//         name: userData['nama_lengkap'] ?? 'Admin Penyemaian',
//         role: 'Admin Penyemaian',
//         photoUrl: userData['photo_url'] ?? '',
//       );
//     } catch (e) {
//       print('Error getting user profile: $e');
//       // Fallback to default profile
//       return UserProfileModel(
//         name: "Admin Penyemaian",
//         role: "Admin Penyemaian", 
//         photoUrl: "",
//       );
//     }
//   }

//   // Get recent activities from Firestore
//   Future<List<ActivityModel>> getRecentActivities() async {
//     try {
//       User? currentUser = _auth.currentUser;
//       if (currentUser == null) {
//         throw Exception('User not authenticated');
//       }

//       // Get activities without ordering in the query
//       QuerySnapshot snapshot = await _firestore
//           .collection('aktivitas')
//           .where('id_user', isEqualTo: currentUser.uid)
//           .get();
      
//       if (snapshot.docs.isEmpty) {
//         return [];
//       }
      
//       // Sort manually in app
//       List<DocumentSnapshot> sortedDocs = snapshot.docs.toList()
//         ..sort((a, b) {
//           Timestamp? timeA = (a.data() as Map<String, dynamic>)['tanggal_waktu'] as Timestamp?;
//           Timestamp? timeB = (b.data() as Map<String, dynamic>)['tanggal_waktu'] as Timestamp?;
          
//           if (timeA == null && timeB == null) return 0;
//           if (timeA == null) return 1;
//           if (timeB == null) return -1;
          
//           return timeB.compareTo(timeA);
//         });
      
//       // Limit to 5 most recent
//       if (sortedDocs.length > 5) {
//         sortedDocs = sortedDocs.sublist(0, 5);
//       }
      
//       // Convert to ActivityModel objects
//       return sortedDocs.map((doc) {
//         Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//         String activityName = data['nama_aktivitas'] ?? '';
        
//         // Determine icon based on activity name
//         IconData icon;
//         if (activityName.toLowerCase().contains('scan')) {
//           icon = Icons.qr_code_scanner_rounded;
//         } else if (activityName.toLowerCase().contains('edit') || 
//                  activityName.toLowerCase().contains('pembaruan')) {
//           icon = Icons.edit_rounded;
//         } else if (activityName.toLowerCase().contains('cetak') || 
//                  activityName.toLowerCase().contains('print')) {
//           icon = Icons.print_rounded;
//         } else if (activityName.toLowerCase().contains('tambah') || 
//                  activityName.toLowerCase().contains('pendaftaran')) {
//           icon = Icons.add_circle_outline_rounded;
//         } else {
//           icon = Icons.article_rounded;
//         }
        
//         // Format time for display
//         final timestamp = data['tanggal_waktu'] as Timestamp?;
//         String timeString = 'Waktu tidak tersedia';

//         if (timestamp != null) {
//           final now = DateTime.now();
//           final activityTime = timestamp.toDate();
//           final difference = now.difference(activityTime);

//           if (difference.inMinutes < 5) {
//             timeString = 'Baru saja';
//           } else if (difference.inHours < 1) {
//             timeString = '${difference.inMinutes} menit yang lalu';
//           } else if (difference.inHours < 24) {
//             timeString = '${difference.inHours} jam yang lalu';
//           } else if (difference.inDays < 2) {
//             timeString = 'Kemarin, ${activityTime.hour}:${activityTime.minute.toString().padLeft(2, '0')}';
//           } else {
//             timeString = '${activityTime.day}/${activityTime.month}/${activityTime.year}';
//           }
//         }
        
//         return ActivityModel(
//           icon: icon,
//           title: activityName,
//           time: timeString,
//           highlight: sortedDocs.indexOf(doc) == 0,
//         );
//       }).toList();
//     } catch (e) {
//       print('Error getting recent activities: $e');
//       return [];
//     }
//   }

//   // Get dashboard statistics from Firestore
//   Future<Map<String, dynamic>> getDashboardStatistics() async {
//     try {
//       User? currentUser = _auth.currentUser;
//       if (currentUser == null) {
//         throw Exception('User not authenticated');
//       }

//       DocumentSnapshot dashboardDoc = await _firestore
//           .collection('dashboard_informasi_admin_penyemaian')
//           .doc(currentUser.uid)
//           .get();

//       if (dashboardDoc.exists) {
//         Map<String, dynamic> data = dashboardDoc.data() as Map<String, dynamic>;
        
//         // Calculate growth if available
//         String pertumbuhanBibit = '0%';
//         if (data['previous_total_bibit'] != null && 
//             data['previous_total_bibit'] > 0 &&
//             data['total_bibit'] != null) {
//           final current = data['total_bibit'] as int;
//           final previous = data['previous_total_bibit'] as int;
//           final growth = ((current - previous) / previous) * 100;
//           pertumbuhanBibit = "${growth > 0 ? '+' : ''}${growth.toStringAsFixed(1)}%";
//         }
        
//         return {
//           'totalBibit': data['total_bibit']?.toString() ?? '0',
//           'bibitSiapTanam': data['bibit_siap_tanam']?.toString() ?? '0',
//           'bibitButuhPerhatian': data['butuh_perhatian']?.toString() ?? '0',
//           'bibitDipindai': data['total_bibit_dipindai']?.toString() ?? '0',
//           'pertumbuhanBibit': pertumbuhanBibit,
//           'growthStatTrend': 'Bulan ini',
//           'scanStatTrend': 'Minggu ini',
//         };
//       } else {
//         // If no dashboard data, return zeros
//         return {
//           'totalBibit': '0',
//           'bibitSiapTanam': '0',
//           'bibitButuhPerhatian': '0',
//           'bibitDipindai': '0',
//           'pertumbuhanBibit': '0%',
//           'growthStatTrend': 'Bulan ini',
//           'scanStatTrend': 'Minggu ini',
//         };
//       }
//     } catch (e) {
//       print('Error getting dashboard statistics: $e');
//       return {
//         'totalBibit': '0',
//         'bibitSiapTanam': '0',
//         'bibitButuhPerhatian': '0',
//         'bibitDipindai': '0',
//         'pertumbuhanBibit': '0%',
//         'growthStatTrend': 'Bulan ini',
//         'scanStatTrend': 'Minggu ini',
//       };
//     }
//   }

//   // Get bibit data from Firestore
//   Future<List<BibitModel>> getBibitData() async {
//     try {
//       User? currentUser = _auth.currentUser;
//       if (currentUser == null) {
//         throw Exception('User not authenticated');
//       }

//       QuerySnapshot bibitSnapshot = await _firestore
//           .collection('bibit')
//           .where('id_user', isEqualTo: currentUser.uid)
//           .limit(10)  // Limit to avoid loading too much data
//           .get();

//       return bibitSnapshot.docs.map((doc) {
//         Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
//         // Convert Firestore timestamp to formatted date string
//         String formatDate(Timestamp? timestamp) {
//           if (timestamp == null) return '';
//           final date = timestamp.toDate();
//           return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
//         }
        
//         // Format age in months based on tanggal_pembibitan
//         String formatAge(Timestamp? timestamp) {
//           if (timestamp == null) return '0 bulan';
//           final plantDate = timestamp.toDate();
//           final now = DateTime.now();
//           final difference = now.difference(plantDate);
//           final months = (difference.inDays / 30).round();
//           return '$months bulan';
//         }
        
//         return BibitModel(
//           id: doc.id,
//           jenisBibit: data['nama_bibit'] ?? 'Tidak ada nama',
//           umur: formatAge(data['tanggal_pembibitan'] as Timestamp?),
//           tinggi: (data['tinggi'] is int) 
//               ? (data['tinggi'] as int).toDouble() 
//               : data['tinggi'] ?? 0.0,
//           kondisi: data['kondisi'] ?? 'Baik',
//           tanggalTanam: formatDate(data['tanggal_pembibitan'] as Timestamp?),
//           lokasi: data['lokasi_tanam'] != null && data['lokasi_tanam']['alamat'] != null
//               ? data['lokasi_tanam']['alamat']
//               : 'Tidak ada lokasi',
//           siapTanam: data['kondisi'] == 'Siap Tanam',
//           butuhPerhatian: data['kondisi'] == 'Butuh Perawatan' || data['kondisi'] == 'Kritis',
//         );
//       }).toList();
//     } catch (e) {
//       print('Error getting bibit data: $e');
//       return [];
//     }
//   }
// }