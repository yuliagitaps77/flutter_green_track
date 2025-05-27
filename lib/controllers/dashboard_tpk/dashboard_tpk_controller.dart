import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/navigation/navigation_controller.dart';
import 'package:flutter_green_track/fitur/authentication/update_profile_screen.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/model/model_dashboard_tpk.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/page_inventory_kayu.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../controllers/authentication/authentication_controller.dart';
import '../../service/services.dart';
import '../../fitur/lacak_history/user_activity_model.dart';
import '../dashboard_pneyemaian/dashboard_penyemaian_controller.dart';

class TPKDashboardController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();

  // Loading state
  RxBool isLoading = false.obs;

  // Selected period for filtering
  RxString selectedPeriod = '6 Bulan'.obs;

  // User profile data
  Rx<UserProfileModel> userProfile =
      UserProfileModel(name: "Admin TPK", role: "Admin TPK", photoUrl: "").obs;

  // Statistics data
  RxString totalWood = "0".obs;
  RxString scannedWood = "0".obs;
  RxString totalBatch = "0".obs;
  RxString woodStatTrend = "Minggu ini".obs;
  RxString scanStatTrend = "Bulan ini".obs;

  // Chart data
  final RxList<FlSpot> inventorySpots = <FlSpot>[
    FlSpot(0, 10),
    FlSpot(1, 14),
    FlSpot(2, 18),
    FlSpot(3, 15),
    FlSpot(4, 20),
    FlSpot(5, 16),
    FlSpot(6, 22),
  ].obs;

  final RxList<FlSpot> revenueSpots = <FlSpot>[
    FlSpot(0, 5),
    FlSpot(1, 8),
    FlSpot(2, 10),
    FlSpot(3, 15),
    FlSpot(4, 18),
    FlSpot(5, 14),
    FlSpot(6, 20),
  ].obs;

  // Quick actions
  final RxList<Map<String, dynamic>> actions = <Map<String, dynamic>>[].obs;

  // Recent activities
  final RxList<ActivityModel> recentActivities = <ActivityModel>[].obs;

  // Menu animation state
  RxBool isMenuOpen = false.obs;

  // Selected action index
  RxInt selectedActionIndex = 0.obs;

  // Current user ID
  String? currentUserId;

  @override
  void onInit() {
    super.onInit();
    initActions();
    initUserData();
    setupRealtimeListeners();
  }

  void setupRealtimeListeners() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Listen to kayu collection changes
    FirebaseFirestore.instance
        .collection('kayu')
        .snapshots()
        .listen((snapshot) {
      calculateWoodStatistics();
    });

    // Listen to scan history changes
    FirebaseFirestore.instance
        .collectionGroup('riwayat_scan')
        .where('id_user', isEqualTo: currentUser.uid)
        .snapshots()
        .listen((snapshot) {
      calculateScanningStatistics();
    });
  }

  Future<void> initUserData() async {
    try {
      print('Initializing user data...');

      // Get current user from local storage
      final user = await _firebaseService.getLocalUser();
      if (user != null) {
        print('User found in local storage');
        currentUserId = user.id;

        // Check if user photoUrl is null before accessing it
        if (user.photoUrl == null) {
          print('Warning: User photoUrl is null, using default photo.');
        }

        // Update user profile with actual user data
        userProfile.value = UserProfileModel(
          name: user.name ?? 'Unknown', // Use a fallback value if null
          role:
              user.role == UserRole.adminTPK ? "Admin TPK" : "Admin Penyemaian",
          photoUrl:
              user.photoUrl ?? 'default_photo_url', // Provide default if null
        );

        fetchDashboardData();
        fetchRecentActivities();
      } else {
        print('User not found in local storage');

        // If no user found in local storage, check Firebase Auth
        final firebaseUser = _firebaseService.getCurrentFirebaseUser();
        if (firebaseUser != null) {
          print('Firebase user found');

          // Get user details from Firestore
          final userData = await _firebaseService.getUserData(firebaseUser.uid);
          if (userData != null) {
            print('User data retrieved from Firestore');
            currentUserId = userData.id;

            // Check if userData photoUrl is null before accessing it
            if (userData.photoUrl == null) {
              print('Warning: User photoUrl is null, using default photo.');
            }

            // Update user profile with data from Firestore
            userProfile.value = UserProfileModel(
              name: userData.name ?? 'Unknown', // Use a fallback value if null
              role: userData.role == UserRole.adminTPK
                  ? "Admin TPK"
                  : "Admin Penyemaian",
              photoUrl: userData.photoUrl ??
                  'default_photo_url', // Provide default if null
            );

            // Save user to local storage
            await _firebaseService.saveUserLocally(userData);

            fetchDashboardData();
            fetchRecentActivities();
          } else {
            print('No user data found in Firestore');
          }
        } else {
          print('No Firebase user found');
        }
      }
    } catch (e) {
      print('Error initializing user data: $e');
    }
  }

  // Initialize actions
  void initActions() {
    actions.assignAll([
      {
        'icon': Icons.qr_code_scanner_rounded,
        'title': 'Scan\nBarcode',
        'onTap': () => handleAction(0),
        'highlight': true,
      },
      {
        'icon': Icons.inventory_2_rounded,
        'title': 'Inventory\nKayu',
        'onTap': () => handleAction(1),
        'highlight': false,
      },
      {
        'icon': Icons.bar_chart,
        'title': 'Statistik\nInventory',
        'onTap': () => handleAction(2),
        'highlight': false,
      },
      {
        'icon': Icons.history_rounded,
        'title': 'Riwayat',
        'onTap': () => handleAction(3),
        'highlight': false,
      },
    ]);
  }

  // Handle action selection
  void handleAction(int index) {
    // Update all highlights
    for (var i = 0; i < actions.length; i++) {
      actions[i]['highlight'] = i == index;
    }

    selectedActionIndex.value = index;
    actions.refresh();

    // Execute the corresponding action
    switch (index) {
      case 0:
        navigateToScanBarcode();
        break;
      case 1:
        navigateToInventory();
        break;
      case 2:
        navigationController.navigateToStatistikInventoryTPK();
        break;
      case 3:
        navigationController.navigateToAktivitasTPK();
        break;
      case 4:
        navigateToReports();
        break;
      case 5:
        navigateToSettings();
        break;
    }
  }

  final navigationController = Get.find<NavigationController>();

  // Method to handle hovering on action card (will be called from UI)
  void handleHover(int index, bool isHovered) {
    // Only set highlight if it's not already the selected index
    if (index != selectedActionIndex.value) {
      actions[index]['highlight'] = isHovered;
      actions.refresh();
    }
  }

  // Navigation methods
  void navigateToScanBarcode() {
    print('Navigating to Scan Barcode page');
    navigationController.goToScan();

    // Get.toNamed('/scan-barcode');
  }

  void navigateToInventory() {
    print('Navigating to Inventory page');
    // Get.toNamed('/inventory');
    navigationController.navigateToInventory();
  }

  void navigateToScanHistory() {
    print('Navigating to Scan History page');
    // Get.toNamed('/scan-history');
  }

  void navigateToDeliverySchedule() {
    print('Navigating to Delivery Schedule page');
    // Get.toNamed('/delivery-schedule');
  }

  void navigateToReports() {
    print('Navigating to Reports page');
    // Get.toNamed('/reports');
  }

  void navigateToSettings() {
    print('Navigating to Settings page');
    Get.toNamed(ProfileUpdateScreen.routeName);
    // Get.toNamed('/settings');
  }

  // Menu handling
  void toggleMenu() {
    isMenuOpen.toggle();
  }

  void openMenu() {
    isMenuOpen.value = true;
  }

  void closeMenu() {
    isMenuOpen.value = false;
  }

  // Profile methods
  void handleProfileTap() {
    print('Profile tapped');
    // Get.toNamed('/profile');
  }

  void logout() {
    // Get the authentication controller and call logout
    final authController = Get.find<AuthenticationController>();
    authController.logout();
  }

  // Handle view all activities
  void viewAllActivities() {
    print('Viewing all activities');
    // Get.toNamed('/activities');
  }

  // Data fetching methods
  Future<void> fetchDashboardData() async {
    try {
      isLoading.value = true;
      await calculateWoodStatistics();
      await calculateScanningStatistics();
    } catch (e) {
      print('Error fetching dashboard data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Calculate statistics for wood inventory and scanning
  Future<void> calculateWoodStatistics() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get wood inventory data
      final QuerySnapshot woodSnapshot =
          await FirebaseFirestore.instance.collection('kayu').get();

      // Calculate total wood and batches
      int totalKayu = 0;
      Set<String> uniqueBatches = {};

      for (var doc in woodSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalKayu += (data['jumlah_stok'] as num?)?.toInt() ?? 0;
        String batchPanen = data['batch_panen'] as String? ?? '';
        if (batchPanen.isNotEmpty) {
          uniqueBatches.add(batchPanen);
        }
      }

      // Update total wood and batch counts
      totalWood.value = totalKayu.toString();
      totalBatch.value = uniqueBatches.length.toString();

      // Calculate trend
      int woodLastWeek = 0;
      for (var doc in woodSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = data['created_at'] as Timestamp?;
        if (createdAt != null &&
            createdAt
                .toDate()
                .isAfter(DateTime.now().subtract(Duration(days: 7)))) {
          woodLastWeek += (data['jumlah_stok'] as num?)?.toInt() ?? 0;
        }
      }
      woodStatTrend.value = "$woodLastWeek kayu minggu ini";

      // Generate inventory spots for chart with dates
      Map<DateTime, int> woodByDate = {};
      DateTime now = DateTime.now();

      // Initialize last 7 days with 0
      for (int i = 6; i >= 0; i--) {
        DateTime date =
            DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        woodByDate[date] = 0;
      }

      // Aggregate data by date
      for (var doc in woodSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = data['created_at'] as Timestamp?;
        if (createdAt != null) {
          DateTime date = DateTime(
            createdAt.toDate().year,
            createdAt.toDate().month,
            createdAt.toDate().day,
          );
          if (date.isAfter(now.subtract(Duration(days: 7)))) {
            final jumlahStok = (data['jumlah_stok'] as num?)?.toInt() ?? 0;
            woodByDate[date] = (woodByDate[date] ?? 0) + jumlahStok;
          }
        }
      }

      // Convert to spots
      List<FlSpot> spots = [];
      List<DateTime> sortedDates = woodByDate.keys.toList()..sort();
      for (int i = 0; i < sortedDates.length; i++) {
        spots.add(
            FlSpot(i.toDouble(), woodByDate[sortedDates[i]]?.toDouble() ?? 0));
      }
      inventorySpots.value = spots;
    } catch (e) {
      print('Error calculating wood statistics: $e');
    }
  }

  Future<void> calculateScanningStatistics() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get scan activities from AppController
      final activities = AppController.to.recentActivities
          .where((activity) =>
              activity.userId == currentUser.uid &&
              activity.activityType == ActivityTypes.scanPohon)
          .toList();

      // Update total scans
      scannedWood.value = activities.length.toString();

      // Calculate trend
      int recentScans = 0;
      for (var activity in activities) {
        if (activity.timestamp
            .isAfter(DateTime.now().subtract(Duration(days: 7)))) {
          recentScans++;
        }
      }
      scanStatTrend.value = "$recentScans pemindaian minggu ini";

      // Generate scanning spots for chart with dates
      Map<DateTime, int> scansByDate = {};
      DateTime now = DateTime.now();

      // Initialize last 7 days with 0
      for (int i = 6; i >= 0; i--) {
        DateTime date =
            DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        scansByDate[date] = 0;
      }

      // Aggregate scans by date
      for (var activity in activities) {
        DateTime date = DateTime(
          activity.timestamp.year,
          activity.timestamp.month,
          activity.timestamp.day,
        );
        if (date.isAfter(now.subtract(Duration(days: 7)))) {
          scansByDate[date] = (scansByDate[date] ?? 0) + 1;
        }
      }

      // Convert to spots
      List<FlSpot> spots = [];
      List<DateTime> sortedDates = scansByDate.keys.toList()..sort();
      for (int i = 0; i < sortedDates.length; i++) {
        spots.add(
            FlSpot(i.toDouble(), scansByDate[sortedDates[i]]?.toDouble() ?? 0));
      }
      revenueSpots.value = spots;
    } catch (e) {
      print('Error calculating scanning statistics: $e');
    }
  }

  // Helper function to format numbers with commas
  String _formatNumber(num number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  void updateChartData() {
    // This could fetch chart data from Firestore if needed
    // For now, we'll use the static data defined in the constructor
  }

  // Get menu items for side menu
  List<Map<String, dynamic>> getMenuItems() {
    return [
      {
        'icon': Icons.dashboard_rounded,
        'title': "Dashboard",
        'isActive': true,
        'onTap': () {
          closeMenu();
        },
      },
      {
        'icon': Icons.settings_rounded,
        'title': "Update Profile Akun",
        'onTap': () {
          closeMenu();
          navigateToSettings();
        },
      },
      {
        'icon': Icons.logout_rounded,
        'title': "Logout",
        'isDestructive': true,
        'onTap': () {
          closeMenu();
          // Show logout confirmation
          _showLogoutConfirmation();
        },
      },
    ];
  }

  // Show change password dialog
  void _showChangePasswordDialog() {
    // Implementation for change password dialog
    // Can use FirebaseAuth.instance.currentUser?.updatePassword()
  }

// Mendapatkan detail kayu berdasarkan ID
  Future<KayuModel?> getKayuDetail(String kayuId) async {
    try {
      final DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection('kayu').doc(kayuId).get();

      if (doc.exists) {
        return KayuModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting kayu detail: $e');
      return null;
    }
  }

// Menambahkan kayu baru

// ====== BATCH CRUD ======

// Perbaikan untuk fetchRecentActivities yang sesuai dengan model ActivityModel
  @override
  Future<void> fetchRecentActivities() async {
    if (currentUserId == null) return;

    try {
      // Get activities without ordering in the query (to avoid needing index)
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('aktivitas')
          .where('id_user', isEqualTo: currentUserId)
          .get();

      if (snapshot.docs.isEmpty) {
        recentActivities.clear();
        return;
      }

      // Sort manually in app instead of in query
      List<DocumentSnapshot> sortedDocs = snapshot.docs.toList()
        ..sort((a, b) {
          Timestamp? timeA =
              (a.data() as Map<String, dynamic>)['tanggal_waktu'] as Timestamp?;
          Timestamp? timeB =
              (b.data() as Map<String, dynamic>)['tanggal_waktu'] as Timestamp?;

          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return 1;
          if (timeB == null) return -1;

          // Sort in descending order (newest first)
          return timeB.compareTo(timeA);
        });

      // Limit to 5 most recent
      if (sortedDocs.length > 5) {
        sortedDocs = sortedDocs.sublist(0, 5);
      }

      // Convert to ActivityModel objects
      List<ActivityModel> activities = [];

      for (var doc in sortedDocs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Determine icon based on activity name
        IconData icon;
        String activityName = data['nama_aktivitas'] ?? '';

        if (activityName.toLowerCase().contains('scan')) {
          icon = Icons.qr_code_scanner_rounded;
        } else if (activityName.toLowerCase().contains('update') ||
            activityName.toLowerCase().contains('perbarui')) {
          icon = Icons.edit_rounded;
        } else if (activityName.toLowerCase().contains('cetak') ||
            activityName.toLowerCase().contains('print')) {
          icon = Icons.print_rounded;
        } else if (activityName.toLowerCase().contains('tambah') ||
            activityName.toLowerCase().contains('daftar')) {
          icon = Icons.add_circle_outline_rounded;
        } else if (activityName.toLowerCase().contains('hapus')) {
          icon = Icons.delete_outline_rounded;
        } else if (activityName.toLowerCase().contains('kirim')) {
          icon = Icons.local_shipping_rounded;
        } else if (activityName.toLowerCase().contains('batch')) {
          icon = Icons.inventory_2_rounded;
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

        activities.add(ActivityModel(
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
          highlight: sortedDocs.indexOf(doc) == 0, // Highlight first item
        ));
      }

      recentActivities.assignAll(activities);
    } catch (e) {
      print('Error fetching activities: $e');
    }
  }

  // Show logout confirmation dialog
  void _showLogoutConfirmation() {
    Get.dialog(
      AlertDialog(
        title: Text('Konfirmasi Logout'),
        content: Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              logout();
            },
            child: Text('Logout'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> refreshDashboardData() async {
    try {
      isLoading.value = true;

      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get wood data from Firestore
      final QuerySnapshot woodSnapshot =
          await FirebaseFirestore.instance.collection('kayu').get();

      // Get scanning data
      final QuerySnapshot scanSnapshot = await FirebaseFirestore.instance
          .collectionGroup('riwayat_scan')
          .where('id_user', isEqualTo: currentUser.uid)
          .get();

      // Calculate totals
      int totalWoodCount = 0;
      Set<String> uniqueBatches = {};

      for (var doc in woodSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalWoodCount += (data['jumlah_stok'] as num?)?.toInt() ?? 0;
        String batchPanen = data['batch_panen'] as String? ?? '';
        if (batchPanen.isNotEmpty) {
          uniqueBatches.add(batchPanen);
        }
      }

      // Update observable values
      totalWood.value = totalWoodCount.toString();
      scannedWood.value = scanSnapshot.docs.length.toString();
      totalBatch.value = uniqueBatches.length.toString();

      // Update chart data
      await _updateChartData();

      print('Dashboard data refreshed successfully:');
      print('Total Wood: ${totalWood.value}');
      print('Scanned Wood: ${scannedWood.value}');
      print('Total Batch: ${totalBatch.value}');
    } catch (e) {
      print('Error refreshing dashboard data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateChartData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get wood data from Firestore
      final QuerySnapshot woodSnapshot = await FirebaseFirestore.instance
          .collection('kayu')
          .orderBy('created_at', descending: true)
          .get();

      // Get scanning data
      final QuerySnapshot scanSnapshot = await FirebaseFirestore.instance
          .collectionGroup('riwayat_scan')
          .where('id_user', isEqualTo: currentUser.uid)
          .orderBy('timestamp', descending: true)
          .get();

      // Create maps to store aggregated data
      Map<DateTime, int> woodByDate = {};
      Map<DateTime, int> scansByDate = {};

      // Get date range for last 7 days
      DateTime now = DateTime.now();
      DateTime startDate = now.subtract(Duration(days: 7));

      // Initialize dates for the last 7 days with 0
      for (int i = 0; i < 7; i++) {
        DateTime date = startDate.add(Duration(days: i));
        DateTime normalizedDate = DateTime(date.year, date.month, date.day);
        woodByDate[normalizedDate] = 0;
        scansByDate[normalizedDate] = 0;
      }

      // Aggregate wood data
      int woodLastWeek = 0;
      for (var doc in woodSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = (data['created_at'] as Timestamp?)?.toDate();
        final stockCount = (data['jumlah_stok'] as num?)?.toInt() ?? 0;

        if (createdAt != null && createdAt.isAfter(startDate)) {
          final normalizedDate = DateTime(
            createdAt.year,
            createdAt.month,
            createdAt.day,
          );
          woodByDate[normalizedDate] =
              (woodByDate[normalizedDate] ?? 0) + stockCount;
          woodLastWeek += stockCount;
        }
      }

      // Aggregate scan data
      int scansLastWeek = 0;
      for (var doc in scanSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

        if (timestamp != null && timestamp.isAfter(startDate)) {
          final normalizedDate = DateTime(
            timestamp.year,
            timestamp.month,
            timestamp.day,
          );
          scansByDate[normalizedDate] = (scansByDate[normalizedDate] ?? 0) + 1;
          scansLastWeek++;
        }
      }

      // Convert to spots
      List<FlSpot> woodSpots = [];
      List<FlSpot> scanSpots = [];

      // Sort dates to ensure correct order
      List<DateTime> sortedDates = woodByDate.keys.toList()..sort();

      for (int i = 0; i < sortedDates.length; i++) {
        DateTime date = sortedDates[i];
        woodSpots.add(FlSpot(i.toDouble(), woodByDate[date]?.toDouble() ?? 0));
        scanSpots.add(FlSpot(i.toDouble(), scansByDate[date]?.toDouble() ?? 0));
      }

      // Update the observable lists
      inventorySpots.assignAll(woodSpots);
      revenueSpots.assignAll(scanSpots);

      // Update trends
      woodStatTrend.value = "$woodLastWeek kayu dalam 7 hari terakhir";
      scanStatTrend.value = "$scansLastWeek pemindaian dalam 7 hari terakhir";

      print('Chart data updated successfully:');
      print('Wood spots: ${woodSpots.length}');
      print('Scan spots: ${scanSpots.length}');
      print('Wood trend: ${woodStatTrend.value}');
      print('Scan trend: ${scanStatTrend.value}');
    } catch (e) {
      print('Error updating chart data: $e');
    }
  }
}

// Model untuk kayu
class KayuModel {
  final String id;
  final String idUser;
  final String namaKayu;
  final String varietas;
  final int usia;
  final double tinggi;
  final String jenisKayu;
  final String catatan;
  final Timestamp createdAt;
  final Timestamp tanggalLahirPohon;
  final List<String> gambarImage;
  final String barcode;
  final String urlBibit;
  final String lokasiTanam;
  final String batchPanen;
  final Timestamp updatedAt;

  KayuModel({
    required this.id,
    required this.idUser,
    required this.namaKayu,
    required this.varietas,
    required this.usia,
    required this.tinggi,
    required this.jenisKayu,
    required this.catatan,
    required this.createdAt,
    required this.tanggalLahirPohon,
    required this.gambarImage,
    required this.barcode,
    required this.urlBibit,
    required this.lokasiTanam,
    required this.batchPanen,
    required this.updatedAt,
  });

  factory KayuModel.fromMap(String id, Map<String, dynamic> data) {
    return KayuModel(
      id: id,
      idUser: data['id_user'] ?? '',
      namaKayu: data['nama_kayu'] ?? '',
      varietas: data['varietas'] ?? '',
      usia: data['usia'] ?? 0,
      tinggi: (data['tinggi'] is int)
          ? (data['tinggi'] as int).toDouble()
          : data['tinggi'] ?? 0.0,
      jenisKayu: data['jenis_kayu'] ?? '',
      catatan: data['catatan'] ?? '',
      createdAt: data['created_at'] as Timestamp? ?? Timestamp.now(),
      tanggalLahirPohon:
          data['tanggal_lahir_pohon'] as Timestamp? ?? Timestamp.now(),
      gambarImage: (data['gambar_image'] as List<dynamic>?)
              ?.map((item) => item.toString())
              ?.toList() ??
          [],
      barcode: data['barcode'] ?? '',
      urlBibit: data['url_bibit'] ?? '',
      lokasiTanam: data['lokasi_tanam'] ?? '',
      batchPanen: data['batch_panen'] ?? '',
      updatedAt: data['updated_at'] as Timestamp? ?? Timestamp.now(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id_user': idUser,
      'nama_kayu': namaKayu,
      'varietas': varietas,
      'usia': usia,
      'tinggi': tinggi,
      'jenis_kayu': jenisKayu,
      'catatan': catatan,
      'created_at': createdAt,
      'tanggal_lahir_pohon': tanggalLahirPohon,
      'gambar_image': gambarImage,
      'barcode': barcode,
      'url_bibit': urlBibit,
      'lokasi_tanam': lokasiTanam,
      'batch_panen': batchPanen,
      'updated_at': updatedAt,
    };
  }
}
