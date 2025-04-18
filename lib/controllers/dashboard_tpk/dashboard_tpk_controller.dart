import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/model/model_dashboard_tpk.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/models/user_model.dart';
import '../../service/services.dart';
import '../../controllers/authentication/authentication_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  // Initialize user data
  Future<void> initUserData() async {
    try {
      // Get current user from local storage
      final user = await _firebaseService.getLocalUser();
      if (user != null) {
        currentUserId = user.id;

        // Update user profile with actual user data
        userProfile.value = UserProfileModel(
          name: user.name,
          role:
              user.role == UserRole.adminTPK ? "Admin TPK" : "Admin Penyemaian",
          photoUrl: user.photoUrl!,
        );

        fetchDashboardData();
        fetchRecentActivities();
      } else {
        print('User not found in local storage');
        // Jika tidak ada user dalam local storage, cek Firebase Auth
        final firebaseUser = _firebaseService.getCurrentFirebaseUser();
        if (firebaseUser != null) {
          // Get user details from Firestore
          final userData = await _firebaseService.getUserData(firebaseUser.uid);
          if (userData != null) {
            currentUserId = userData.id;

            // Update user profile with data from Firestore
            userProfile.value = UserProfileModel(
              name: userData.name,
              role: userData.role == UserRole.adminTPK
                  ? "Admin TPK"
                  : "Admin Penyemaian",
              photoUrl: userData.photoUrl!,
            );

            // Simpan user ke local storage
            await _firebaseService.saveUserLocally(userData);

            fetchDashboardData();
            fetchRecentActivities();
          }
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
        'icon': Icons.local_shipping_rounded,
        'title': 'Jadwal\nPengiriman',
        'onTap': () => handleAction(3),
        'highlight': false,
      },
      {
        'icon': Icons.assessment_rounded,
        'title': 'Laporan\nTPK',
        'onTap': () => handleAction(4),
        'highlight': false,
      },
      {
        'icon': Icons.settings_rounded,
        'title': 'Pengaturan\nTPK',
        'onTap': () => handleAction(5),
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
        navigateToScanHistory();
        break;
      case 3:
        navigateToDeliverySchedule();
        break;
      case 4:
        navigateToReports();
        break;
      case 5:
        navigateToSettings();
        break;
    }
  }

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
    // Get.toNamed('/scan-barcode');
  }

  void navigateToInventory() {
    print('Navigating to Inventory page');
    // Get.toNamed('/inventory');
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
        'title': "Pengaturan",
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
// Tambahkan fungsi-fungsi CRUD ini ke TPKDashboardController

// ====== STATISTIK DASHBOARD ======

// Update statistik dashboard berdasarkan data kayu terbaru
  Future<void> updateKayuStatistics() async {
    if (currentUserId == null) return;

    try {
      // Hitung langsung dari koleksi kayu
      final dashboardData = await _calculateTPKDashboardData(currentUserId!);

      // Update dashboard di UI
      totalWood.value = _formatNumber(dashboardData['total_kayu'] ?? 0);
      scannedWood.value =
          _formatNumber(dashboardData['total_kayu_dipindai'] ?? 0);
      totalBatch.value = _formatNumber(dashboardData['total_batch'] ?? 0);
    } catch (e) {
      print('Error updating kayu statistics: $e');
    }
  }

// ====== KAYU CRUD ======

// Mendapatkan daftar kayu dengan paginasi
  Future<List<KayuModel>> getKayuList({
    int limit = 10,
    DocumentSnapshot? startAfter,
    String? searchQuery,
    String? filterBatch,
  }) async {
    try {
      if (currentUserId == null) return [];

      Query query = FirebaseFirestore.instance
          .collection('kayu')
          .where('id_user', isEqualTo: currentUserId)
          .limit(limit);

      // Terapkan filter jika ada
      if (filterBatch != null && filterBatch.isNotEmpty) {
        query = query.where('batch_panen', isEqualTo: filterBatch);
      }

      // Terapkan sorting
      query = query.orderBy('created_at', descending: true);

      // Terapkan pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      // Eksekusi query
      final QuerySnapshot snapshot = await query.get();

      // Jika ada query pencarian, filter hasil secara manual
      List<KayuModel> kayuList = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final KayuModel kayu = KayuModel.fromMap(doc.id, data);

            // Filter berdasarkan pencarian jika ada
            if (searchQuery != null && searchQuery.isNotEmpty) {
              final String namaKayu = kayu.namaKayu.toLowerCase();
              final String varietas = kayu.varietas.toLowerCase();
              final search = searchQuery.toLowerCase();

              if (!namaKayu.contains(search) && !varietas.contains(search)) {
                return null;
              }
            }
            return kayu;
          })
          .whereType<KayuModel>()
          .toList();

      return kayuList;
    } catch (e) {
      print('Error getting kayu list: $e');
      return [];
    }
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
  Future<String?> addKayu(Map<String, dynamic> kayuData) async {
    try {
      if (currentUserId == null) return null;

      // Buat ID kayu baru
      final DocumentReference kayuRef =
          FirebaseFirestore.instance.collection('kayu').doc();

      // Tambahkan data kayu
      await kayuRef.set({
        'id_user': currentUserId,
        'nama_kayu': kayuData['nama_kayu'] ?? '',
        'varietas': kayuData['varietas'] ?? '',
        'usia': kayuData['usia'] ?? 0,
        'tinggi': kayuData['tinggi'] ?? 0.0,
        'jenis_kayu': kayuData['jenis_kayu'] ?? '',
        'catatan': kayuData['catatan'] ?? '',
        'created_at': FieldValue.serverTimestamp(),
        'tanggal_lahir_pohon':
            kayuData['tanggal_lahir_pohon'] ?? Timestamp.now(),
        'gambar_image': kayuData['gambar_image'] ?? [],
        'barcode':
            'KY${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(10000)}',
        'url_bibit': 'https://yourapp.com/kayu/${kayuRef.id}',
        'lokasi_tanam': kayuData['lokasi_tanam'] ?? '',
        'batch_panen': kayuData['batch_panen'] ?? '',
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Rekam aktivitas
      await recordActivity(
          'Pendaftaran Kayu ${kayuData['nama_kayu']}', 'kayu', kayuRef.id);

      // Update statistik dashboard
      await updateKayuStatistics();

      return kayuRef.id;
    } catch (e) {
      print('Error adding kayu: $e');
      return null;
    }
  }

// Memperbarui data kayu
  Future<bool> updateKayu(String kayuId, Map<String, dynamic> kayuData) async {
    try {
      await FirebaseFirestore.instance.collection('kayu').doc(kayuId).update({
        'nama_kayu': kayuData['nama_kayu'],
        'varietas': kayuData['varietas'],
        'usia': kayuData['usia'],
        'tinggi': kayuData['tinggi'],
        'jenis_kayu': kayuData['jenis_kayu'],
        'catatan': kayuData['catatan'],
        'tanggal_lahir_pohon': kayuData['tanggal_lahir_pohon'],
        'gambar_image': kayuData['gambar_image'],
        'lokasi_tanam': kayuData['lokasi_tanam'],
        'batch_panen': kayuData['batch_panen'],
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Rekam aktivitas
      await recordActivity(
          'Pembaruan Data Kayu ${kayuData['nama_kayu']}', 'kayu', kayuId);

      // Update statistik dashboard
      await updateKayuStatistics();

      return true;
    } catch (e) {
      print('Error updating kayu: $e');
      return false;
    }
  }

// Menghapus kayu
  Future<bool> deleteKayu(String kayuId, String namaKayu) async {
    try {
      // Dapatkan riwayat scan dan hapus
      QuerySnapshot scanHistories = await FirebaseFirestore.instance
          .collection('kayu')
          .doc(kayuId)
          .collection('riwayat_scan')
          .get();

      // Hapus semua riwayat scan
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in scanHistories.docs) {
        batch.delete(doc.reference);
      }

      // Hapus dokumen kayu
      batch.delete(FirebaseFirestore.instance.collection('kayu').doc(kayuId));

      // Commit batch delete
      await batch.commit();

      // Rekam aktivitas
      await recordActivity('Penghapusan Kayu $namaKayu', 'kayu', kayuId);

      // Update statistik dashboard
      await updateKayuStatistics();

      return true;
    } catch (e) {
      print('Error deleting kayu: $e');
      return false;
    }
  }

// Memindai barcode kayu
  Future<bool> scanKayu(String kayuId) async {
    try {
      if (currentUserId == null) return false;

      // Tambahkan riwayat pemindaian
      await FirebaseFirestore.instance
          .collection('kayu')
          .doc(kayuId)
          .collection('riwayat_scan')
          .add({
        'id_user': currentUserId,
        'tanggal': Timestamp.now(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Ambil data kayu untuk aktivitas
      DocumentSnapshot kayuDoc =
          await FirebaseFirestore.instance.collection('kayu').doc(kayuId).get();

      if (kayuDoc.exists) {
        Map<String, dynamic> kayuData = kayuDoc.data() as Map<String, dynamic>;
        String namaKayu = kayuData['nama_kayu'] ?? 'Kayu';

        // Rekam aktivitas
        await recordActivity('Scan Barcode $namaKayu', 'kayu', kayuId);

        // Update statistik dashboard
        await updateKayuStatistics();

        return true;
      }

      return false;
    } catch (e) {
      print('Error scanning kayu: $e');
      return false;
    }
  }

// ====== BATCH CRUD ======

// Mendapatkan semua batch yang tersedia
  Future<List<String>> getAllBatches() async {
    try {
      if (currentUserId == null) return [];

      QuerySnapshot kayuSnapshot = await FirebaseFirestore.instance
          .collection('kayu')
          .where('id_user', isEqualTo: currentUserId)
          .get();

      Set<String> uniqueBatches = {};

      for (var doc in kayuSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String batchPanen = data['batch_panen'] as String? ?? '';
        if (batchPanen.isNotEmpty) {
          uniqueBatches.add(batchPanen);
        }
      }

      return uniqueBatches.toList()..sort();
    } catch (e) {
      print('Error getting batch list: $e');
      return [];
    }
  }

// Mendapatkan detail batch
  Future<Map<String, dynamic>> getBatchDetails(String batchId) async {
    try {
      if (currentUserId == null) return {};

      QuerySnapshot kayuSnapshot = await FirebaseFirestore.instance
          .collection('kayu')
          .where('id_user', isEqualTo: currentUserId)
          .where('batch_panen', isEqualTo: batchId)
          .get();

      // Hitung statistik batch
      int totalKayu = kayuSnapshot.docs.length;
      int totalKayuDipindai = 0;

      // Jenis kayu dalam batch ini
      Map<String, int> jenisKayu = {};

      for (var doc in kayuSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String kayuId = doc.id;

        // Hitung jenis kayu
        String namaKayu = data['nama_kayu'] as String? ?? 'Tidak diketahui';
        jenisKayu[namaKayu] = (jenisKayu[namaKayu] ?? 0) + 1;

        // Periksa apakah kayu telah dipindai
        QuerySnapshot scanSnapshot = await FirebaseFirestore.instance
            .collection('kayu')
            .doc(kayuId)
            .collection('riwayat_scan')
            .limit(1)
            .get();

        if (scanSnapshot.docs.isNotEmpty) {
          totalKayuDipindai++;
        }
      }

      return {
        'batch_id': batchId,
        'total_kayu': totalKayu,
        'total_kayu_dipindai': totalKayuDipindai,
        'jenis_kayu': jenisKayu,
        'persentase_dipindai': totalKayu > 0
            ? (totalKayuDipindai / totalKayu * 100).toStringAsFixed(1) + '%'
            : '0%',
      };
    } catch (e) {
      print('Error getting batch details: $e');
      return {};
    }
  }

// Menambahkan batch baru
  Future<bool> addBatch(String batchId, List<String> kayuIds) async {
    try {
      if (currentUserId == null) return false;

      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Update setiap kayu dengan batch baru
      for (String kayuId in kayuIds) {
        DocumentReference kayuRef =
            FirebaseFirestore.instance.collection('kayu').doc(kayuId);
        batch.update(kayuRef, {
          'batch_panen': batchId,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Rekam aktivitas
      await recordActivity(
          'Membuat Batch Baru: $batchId (${kayuIds.length} kayu)',
          'batch',
          batchId);

      // Update statistik
      await updateKayuStatistics();

      return true;
    } catch (e) {
      print('Error adding batch: $e');
      return false;
    }
  }

// Memperbarui batch
  Future<bool> updateBatch(String oldBatchId, String newBatchId) async {
    try {
      if (currentUserId == null) return false;
      if (oldBatchId == newBatchId) return true; // Tidak ada perubahan

      // Ambil semua kayu dengan batch lama
      QuerySnapshot kayuSnapshot = await FirebaseFirestore.instance
          .collection('kayu')
          .where('id_user', isEqualTo: currentUserId)
          .where('batch_panen', isEqualTo: oldBatchId)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Update setiap kayu dengan batch baru
      for (var doc in kayuSnapshot.docs) {
        batch.update(doc.reference, {
          'batch_panen': newBatchId,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Rekam aktivitas
      await recordActivity('Memperbarui Batch $oldBatchId menjadi $newBatchId',
          'batch', newBatchId);

      // Update statistik
      await updateKayuStatistics();

      return true;
    } catch (e) {
      print('Error updating batch: $e');
      return false;
    }
  }

// ====== RIWAYAT SCAN CRUD ======

// Mendapatkan riwayat scan untuk kayu tertentu
  Future<List<ScanHistoryModel>> getKayuScanHistory(String kayuId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('kayu')
          .doc(kayuId)
          .collection('riwayat_scan')
          .orderBy('tanggal', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return ScanHistoryModel.fromMap(doc.id, data);
      }).toList();
    } catch (e) {
      print('Error getting scan history: $e');
      return [];
    }
  }

// Mendapatkan semua riwayat scan
  Future<List<Map<String, dynamic>>> getAllScanHistory({int limit = 50}) async {
    try {
      if (currentUserId == null) return [];

      // Dapatkan semua kayu milik user ini
      QuerySnapshot kayuSnapshot = await FirebaseFirestore.instance
          .collection('kayu')
          .where('id_user', isEqualTo: currentUserId)
          .get();

      List<Map<String, dynamic>> allScans = [];

      // Untuk setiap kayu, dapatkan riwayat pemindaian
      for (var kayuDoc in kayuSnapshot.docs) {
        final String kayuId = kayuDoc.id;
        final Map<String, dynamic> kayuData =
            kayuDoc.data() as Map<String, dynamic>;
        final String namaKayu = kayuData['nama_kayu'] ?? 'Kayu';
        final String varietas = kayuData['varietas'] ?? '';
        final String batchPanen = kayuData['batch_panen'] ?? '';

        QuerySnapshot scanSnapshot = await FirebaseFirestore.instance
            .collection('kayu')
            .doc(kayuId)
            .collection('riwayat_scan')
            .orderBy('tanggal', descending: true)
            .get();

        for (var scanDoc in scanSnapshot.docs) {
          Map<String, dynamic> scanData =
              scanDoc.data() as Map<String, dynamic>;
          allScans.add({
            'scanId': scanDoc.id,
            'kayuId': kayuId,
            'namaKayu': namaKayu,
            'varietas': varietas,
            'batchPanen': batchPanen,
            'tanggal': scanData['tanggal'],
            'id_user': scanData['id_user'],
            'created_at': scanData['created_at'],
          });
        }
      }

      // Urutkan semua riwayat berdasarkan tanggal
      allScans.sort((a, b) {
        Timestamp? timeA = a['tanggal'] as Timestamp?;
        Timestamp? timeB = b['tanggal'] as Timestamp?;

        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;

        return timeB.compareTo(timeA); // Descending order (terbaru dulu)
      });

      // Batasi jumlah hasil
      if (allScans.length > limit) {
        allScans = allScans.sublist(0, limit);
      }

      return allScans;
    } catch (e) {
      print('Error getting all scan history: $e');
      return [];
    }
  }

// ====== AKTIVITAS ======

// Fungsi untuk mencatat aktivitas
  Future<void> recordActivity(
      String namaAktivitas, String tipeObjek, String idObjek) async {
    try {
      if (currentUserId == null) return;

      await FirebaseFirestore.instance.collection('aktivitas').add({
        'id_user': currentUserId,
        'nama_aktivitas': namaAktivitas,
        'tipe_objek': tipeObjek,
        'id_objek': idObjek,
        'tanggal_waktu': Timestamp.now(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Refresh aktivitas di UI
      await fetchRecentActivities();
    } catch (e) {
      print('Error recording activity: $e');
    }
  }

// Mendapatkan semua aktivitas
  Future<List<ActivityModel>> getAllActivities({int limit = 20}) async {
    try {
      if (currentUserId == null) return [];

      // Get activities without ordering in the query (to avoid needing index)
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('aktivitas')
          .where('id_user', isEqualTo: currentUserId)
          .get();

      if (snapshot.docs.isEmpty) return [];

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

      // Limit to requested number
      if (sortedDocs.length > limit) {
        sortedDocs = sortedDocs.sublist(0, limit);
      }

      // Convert to activity models
      List<ActivityModel> activities = [];

      for (var doc in sortedDocs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Determine icon based on activity type
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

      return activities;
    } catch (e) {
      print('Error getting all activities: $e');
      return [];
    }
  }

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
