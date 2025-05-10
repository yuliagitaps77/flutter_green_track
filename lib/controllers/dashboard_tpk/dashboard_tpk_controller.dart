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

import '../../controllers/authentication/authentication_controller.dart';
import '../../service/services.dart';
import '../dashboard_pneyemaian/dashboard_penyemaian_controller.dart';

class TPKDashboardController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();

  // Loading state
  RxBool isLoading = false.obs;

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
        'icon': Icons.history_rounded,
        'title': 'Riwayat\nScan',
        'onTap': () => handleAction(2),
        'highlight': false,
      },
      {
        'icon': Icons.bar_chart,
        'title': 'Data\nStatistik',
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
    if (currentUserId == null) return;

    isLoading.value = true;
    try {
      // Fetch dashboard data directly from kayu collection
      final dashboardData = await _calculateTPKDashboardData(currentUserId!);

      if (dashboardData.isNotEmpty) {
        // Format numbers with commas if needed
        totalWood.value = _formatNumber(dashboardData['total_kayu'] ?? 0);
        scannedWood.value =
            _formatNumber(dashboardData['total_kayu_dipindai'] ?? 0);
        totalBatch.value = _formatNumber(dashboardData['total_batch'] ?? 0);
      }

      // Update chart data if needed
      updateChartData();
    } catch (e) {
      print('Error fetching dashboard data: $e');
      // Handle error appropriately
    } finally {
      isLoading.value = false;
    }
  }

  // Helper function to calculate TPK dashboard data directly from collections
  Future<Map<String, dynamic>> _calculateTPKDashboardData(String userId) async {
    try {
      // Coba ambil dari cache lokal dulu untuk performa
      final prefs = await SharedPreferences.getInstance();
      final String cacheKey = 'dashboard_tpk_$userId';
      final String? cachedData = prefs.getString(cacheKey);
      final int cacheExpiry = prefs.getInt('${cacheKey}_expiry') ?? 0;

      // Jika cache masih valid (tidak lebih dari 5 menit), gunakan cache
      if (cachedData != null &&
          cacheExpiry > DateTime.now().millisecondsSinceEpoch) {
        return jsonDecode(cachedData);
      }

      // Get all kayu documents for this user
      final QuerySnapshot kayuSnapshot = await FirebaseFirestore.instance
          .collection('kayu')
          .where('id_user', isEqualTo: userId)
          .get();

      // Initialize counters
      int totalKayu = kayuSnapshot.docs.length;
      int totalKayuDipindai = 0;
      Set<String> uniqueBatches = {};

      // Process each kayu document
      for (var doc in kayuSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String kayuId = doc.id;

        // Add batch to unique batches if it exists
        String batchPanen = data['batch_panen'] as String? ?? '';
        if (batchPanen.isNotEmpty) {
          uniqueBatches.add(batchPanen);
        }

        // Check if this kayu has been scanned
        try {
          QuerySnapshot scanSnapshot = await FirebaseFirestore.instance
              .collection('kayu')
              .doc(kayuId)
              .collection('riwayat_scan')
              .limit(1)
              .get();

          if (scanSnapshot.docs.isNotEmpty) {
            totalKayuDipindai++;
          }
        } catch (e) {
          print('Error checking scan history for kayu $kayuId: $e');
        }
      }

      // Buat hasil perhitungan
      final Map<String, dynamic> result = {
        'total_kayu': totalKayu,
        'total_kayu_dipindai': totalKayuDipindai,
        'total_batch': uniqueBatches.length,
      };

      // Simpan hasil ke cache untuk 5 menit
      await prefs.setString(cacheKey, jsonEncode(result));
      await prefs.setInt('${cacheKey}_expiry',
          DateTime.now().add(Duration(minutes: 5)).millisecondsSinceEpoch);

      // Cache the calculated data to Firestore
      await _cacheTPKDashboardData(userId, {
        'total_kayu': totalKayu,
        'total_kayu_dipindai': totalKayuDipindai,
        'total_batch': uniqueBatches.length,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return result;
    } catch (e) {
      print('Error calculating TPK dashboard data: $e');

      // Try to get data from Firestore cache if calculation fails
      try {
        final cachedData = await _getTPKDashboardData(userId);
        if (cachedData.isNotEmpty) {
          return cachedData;
        }
      } catch (_) {
        // Ignore cache errors
      }

      return {};
    }
  }

  // Helper function to cache dashboard data to Firestore
  Future<void> _cacheTPKDashboardData(
      String userId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('dashboard_informasi_admin_tpk')
          .doc(userId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error caching TPK dashboard data: $e');
    }
  }

  // Helper function to get cached TPK dashboard data from Firestore
  Future<Map<String, dynamic>> _getTPKDashboardData(String userId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('dashboard_informasi_admin_tpk')
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Error getting TPK dashboard data: $e');
      return {};
    }
  }

  // Add function to refresh dashboard data manually
  Future<void> refreshDashboardData() async {
    if (currentUserId == null) return;

    isLoading.value = true;
    try {
      // Clear local cache
      final prefs = await SharedPreferences.getInstance();
      final String cacheKey = 'dashboard_tpk_${currentUserId}';
      await prefs.remove(cacheKey);
      await prefs.remove('${cacheKey}_expiry');

      // Force recalculation of dashboard data
      final dashboardData = await _calculateTPKDashboardData(currentUserId!);

      if (dashboardData.isNotEmpty) {
        totalWood.value = _formatNumber(dashboardData['total_kayu'] ?? 0);
        scannedWood.value =
            _formatNumber(dashboardData['total_kayu_dipindai'] ?? 0);
        totalBatch.value = _formatNumber(dashboardData['total_batch'] ?? 0);
      }

      // Also refresh activities
      await fetchRecentActivities();

      // Show success message
      Get.snackbar(
        'Sukses',
        'Data dashboard berhasil diperbarui',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      print('Error refreshing dashboard data: $e');
      Get.snackbar(
        'Gagal',
        'Gagal memperbarui data dashboard',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
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
        'icon': Icons.refresh_rounded,
        'title': "Refresh Data",
        'onTap': () {
          closeMenu();
          refreshDashboardData();
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
        'icon': Icons.lock_outline_rounded,
        'title': "Ubah Kata Sandi",
        'onTap': () {
          closeMenu();
          // Show change password dialog
          _showChangePasswordDialog();
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
