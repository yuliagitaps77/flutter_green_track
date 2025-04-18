import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/model/model_dashboard_tpk.dart';

import '../../../controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';

class DashboardTpkRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user profile from Firestore
  Future<UserProfileModel> getUserProfile() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      DocumentSnapshot userDoc =
          await _firestore.collection('akun').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      return UserProfileModel(
        name: userData['nama_lengkap'] ?? 'Admin TPK',
        role: 'Admin TPK',
        photoUrl: userData['photo_url'] ?? '',
      );
    } catch (e) {
      print('Error getting user profile: $e');
      // Fallback to default profile
      return UserProfileModel(
        name: "Admin TPK",
        role: "Admin TPK",
        photoUrl: "",
      );
    }
  }

  // Get recent activities from Firestore
  Future<List<ActivityModel>> getRecentActivities() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get activities without ordering in the query
      QuerySnapshot snapshot = await _firestore
          .collection('aktivitas')
          .where('id_user', isEqualTo: currentUser.uid)
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      // Sort manually in app
      List<DocumentSnapshot> sortedDocs = snapshot.docs.toList()
        ..sort((a, b) {
          Timestamp? timeA =
              (a.data() as Map<String, dynamic>)['tanggal_waktu'] as Timestamp?;
          Timestamp? timeB =
              (b.data() as Map<String, dynamic>)['tanggal_waktu'] as Timestamp?;

          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return 1;
          if (timeB == null) return -1;

          return timeB.compareTo(timeA);
        });

      // Limit to 5 most recent
      if (sortedDocs.length > 5) {
        sortedDocs = sortedDocs.sublist(0, 5);
      }

      // Convert to ActivityModel objects
      return sortedDocs.map((doc) {
        Map<String, dynamic> data = doc!.data() as Map<String, dynamic>;
        String activityName = data['nama_aktivitas'] ?? '';

        // Determine icon based on activity name
        IconData icon;
        if (activityName.toLowerCase().contains('scan')) {
          icon = Icons.qr_code_scanner_rounded;
        } else if (activityName.toLowerCase().contains('update')) {
          icon = Icons.edit_rounded;
        } else if (activityName.toLowerCase().contains('cetak')) {
          icon = Icons.print_rounded;
        } else if (activityName.toLowerCase().contains('tambah')) {
          icon = Icons.add_circle_outline_rounded;
        } else {
          icon = Icons.article_rounded;
        }

        // Format time for display
        final timestamp = data['tanggal_waktu'] as Timestamp?;
        String timeString = 'Waktu tidak tersedia';

        if (timestamp != null) {
          final now = DateTime.now();
          final activityTime = timestamp.toDate();
          final difference = now.difference(activityTime);

          if (difference.inMinutes < 5) {
            timeString = 'Baru saja';
          } else if (difference.inHours < 1) {
            timeString = '${difference.inMinutes} menit yang lalu';
          } else if (difference.inHours < 24) {
            timeString = '${difference.inHours} jam yang lalu';
          } else if (difference.inDays < 2) {
            timeString =
                'Kemarin, ${activityTime.hour}:${activityTime.minute.toString().padLeft(2, '0')}';
          } else {
            timeString =
                '${activityTime.day}/${activityTime.month}/${activityTime.year}';
          }
        }

        return ActivityModel(
          id: doc.id,
          idUser: data['id_user'] ?? '',
          namaAktivitas: activityName,
          tipeObjek: data['tipe_objek'],
          idObjek: data['id_objek'],
          tanggalWaktu: timestamp ?? Timestamp.now(),
          createdAt: data['created_at'] as Timestamp? ?? Timestamp.now(),
          updatedAt: data['updated_at'] as Timestamp? ?? Timestamp.now(),
          icon: icon,
          time: timeString,
          highlight: sortedDocs.indexOf(doc) == 0,
        );
      }).toList();
    } catch (e) {
      print('Error getting recent activities: $e');
      return [];
    }
  }

  // Get dashboard statistics from Firestore
  Future<Map<String, dynamic>> getDashboardStatistics() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      DocumentSnapshot dashboardDoc = await _firestore
          .collection('dashboard_informasi_admin_tpk')
          .doc(currentUser.uid)
          .get();

      if (dashboardDoc.exists) {
        Map<String, dynamic> data = dashboardDoc.data() as Map<String, dynamic>;

        return {
          'totalWood': data['total_kayu']?.toString() ?? '0',
          'scannedWood': data['total_kayu_dipindai']?.toString() ?? '0',
          'totalBatch': data['total_batch']?.toString() ?? '0',
          'woodStatTrend': 'Minggu ini',
          'scanStatTrend': 'Bulan ini',
        };
      } else {
        // If no dashboard data, return zeros
        return {
          'totalWood': '0',
          'scannedWood': '0',
          'totalBatch': '0',
          'woodStatTrend': 'Minggu ini',
          'scanStatTrend': 'Bulan ini',
        };
      }
    } catch (e) {
      print('Error getting dashboard statistics: $e');
      return {
        'totalWood': '0',
        'scannedWood': '0',
        'totalBatch': '0',
        'woodStatTrend': 'Minggu ini',
        'scanStatTrend': 'Bulan ini',
      };
    }
  }

  // Get inventory data from Firestore
  Future<List<InventoryModel>> getInventoryData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      QuerySnapshot kayuSnapshot = await _firestore
          .collection('kayu')
          .where('id_user', isEqualTo: currentUser.uid)
          .get();

      // Group by wood type
      Map<String, int> woodTypeCount = {};
      Map<String, String> lastUpdated = {};

      for (var doc in kayuSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String woodType = data['nama_kayu'] ?? 'Tidak diketahui';
        Timestamp updatedAt =
            data['updated_at'] as Timestamp? ?? Timestamp.now();

        // Count by wood type
        woodTypeCount[woodType] = (woodTypeCount[woodType] ?? 0) + 1;

        // Format date for display
        String formattedDate = '${updatedAt.toDate().year}-'
            '${updatedAt.toDate().month.toString().padLeft(2, '0')}-'
            '${updatedAt.toDate().day.toString().padLeft(2, '0')}';

        // Keep track of latest update for each wood type
        if (lastUpdated[woodType] == null) {
          lastUpdated[woodType] = formattedDate;
        } else {
          DateTime existingDate = DateTime.parse(lastUpdated[woodType]!);
          if (updatedAt.toDate().isAfter(existingDate)) {
            lastUpdated[woodType] = formattedDate;
          }
        }
      }

      // Convert to inventory models
      List<InventoryModel> inventory = [];
      woodTypeCount.forEach((type, count) {
        inventory.add(InventoryModel(
          woodType: type,
          quantity: count,
          lastUpdated: lastUpdated[type] ?? 'Tidak diketahui',
        ));
      });

      return inventory;
    } catch (e) {
      print('Error getting inventory data: $e');
      return [];
    }
  }
}
