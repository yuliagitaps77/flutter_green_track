import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';
import 'package:flutter_green_track/controllers/navigation/navigation_controller.dart';
import 'package:flutter_green_track/fitur/jadwal_perawatan/jadwal_perawatan_page.dart';
import 'package:flutter_green_track/service/services.dart';
import 'package:get/get.dart';

import '../../fitur/dashboard_penyemaian/page_cetak_bibit.dart';
import '../../fitur/dashboard_tpk/model/model_dashboard_tpk.dart';

class PenyemaianDashboardController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();

  // Loading state
  RxBool isLoading = false.obs;

  // User profile data
  Rx<UserProfileModel> userProfile = UserProfileModel(
          name: "Yulia Gita A", role: "Admin Penyemaian", photoUrl: "")
      .obs;

  // Statistics data
  RxString totalBibit = "0".obs;
  RxString bibitSiapTanam = "0".obs;
  RxString bibitButuhPerhatian = "0".obs;
  RxString bibitDipindai = "0".obs;
  RxString pertumbuhanBibit = "0%".obs;
  RxString growthStatTrend = "Bulan ini".obs;
  RxString scanStatTrend = "Minggu ini".obs;

  // Chart data
  final RxList<FlSpot> growthSpots = <FlSpot>[
    FlSpot(0, 2.5),
    FlSpot(1, 3.1),
    FlSpot(2, 3.6),
    FlSpot(3, 4.2),
    FlSpot(4, 4.5),
    FlSpot(5, 5.3),
    FlSpot(6, 5.9),
  ].obs;

  final RxList<FlSpot> scannedSpots = <FlSpot>[
    FlSpot(0, 5),
    FlSpot(1, 12),
    FlSpot(2, 8),
    FlSpot(3, 18),
    FlSpot(4, 10),
    FlSpot(5, 15),
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
      print('Initializing user data...');

      // Get current user from local storage
      final user = await _firebaseService.getLocalUser();
      if (user != null) {
        print('User found in local storage');
        currentUserId = user.id;

        // Update user profile with actual user data
        print('Updating user profile...');
        print('User Name: ${user.name}');
        print('User Role: ${user.role}');
        print('User Photo URL: ${user.photoUrl}');

        userProfile.value = UserProfileModel(
          name: user.name ?? 'Unknown', // Use a fallback value if null
          role: user.role == UserRole.adminPenyemaian
              ? "Admin Penyemaian"
              : "Admin TPK",
          photoUrl: user.photoUrl ??
              'default_photo_url', // Provide default URL if null
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
            print('User Name: ${userData.name}');
            print('User Role: ${userData.role}');
            print('User Photo URL: ${userData.photoUrl}');

            currentUserId = userData.id;

            // Update user profile with data from Firestore
            userProfile.value = UserProfileModel(
              name: userData.name ?? 'Unknown', // Use a fallback value if null
              role: userData.role == UserRole.adminPenyemaian
                  ? "Admin Penyemaian"
                  : "Admin TPK",
              photoUrl:
                  userData.photoUrl ?? 'default_photo_url', // Fallback URL
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
      print('Error initializing user data: ${e}');
    }
  }

  final navigationController = Get.find<NavigationController>();

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
        'icon': Icons.print_rounded,
        'title': 'Cetak\nBarcode',
        'onTap': () => handleAction(1),
        'highlight': false,
      },
      {
        'icon': Icons.forest_rounded,
        'title': 'Daftar\nBibit',
        'onTap': () => handleAction(2),
        'highlight': false,
      },
      {
        'icon': Icons.calendar_month_rounded,
        'title': 'Jadwal\nRawat',
        'onTap': () => handleAction(3),
        'highlight': false,
      },
      {
        'icon': Icons.history,
        'title': 'Riwayat\nScan',
        'onTap': () => handleAction(4),
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
        navigateToPrintBarcode();
        break;
      case 2:
        navigateToDaftarBibit();
        break;
      case 3:
        navigateToJadwalRawat();
        break;
      case 4:
        navigateToRiwayatScan();
        break;
      case 5:
        navigateToUpdateBibit();
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

  // Navigation methods remain the same as in original code
  void navigateToScanBarcode() {
    print('Navigating to Scan Barcode page');
    // Get.toNamed('/scan-barcode');
    navigationController.goToScan();
  }

  void navigateToPrintBarcode() {
    print('Navigating to Print Barcode page');
    Get.toNamed(CetakBarcodeBibitPage.routeName);
  }

  void navigateToDaftarBibit() {
    print('Navigating to Plant List page');

    // Get.toNamed('/daftar-bibit');
    navigationController.navigateToInventory();
  }

  void navigateToJadwalRawat() {
    print('Navigating to Care Schedule page');
    // Get.toNamed('/jadwal-rawat');
    Get.to(PlantCareScheduleScreen());
  }

  void navigateToRiwayatScan() {
    print('Navigating to Scan History page');
    navigationController.navigateToHistory();

    // Get.toNamed('/riwayat-scan');
  }

  void navigateToUpdateBibit() {
    print('Navigating to Update Plant Info page');
    // Get.toNamed('/update-bibit');
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
// Data fetching methods
  Future<void> fetchDashboardData() async {
    if (currentUserId == null) return;

    isLoading.value = true;
    try {
      // Fetch dashboard data directly from collections
      final dashboardData =
          await _firebaseService.getPenyemaianDashboardData(currentUserId!);

      if (dashboardData.isNotEmpty) {
        // Format numbers with commas if needed
        totalBibit.value = _formatNumber(dashboardData['total_bibit'] ?? 0);
        bibitSiapTanam.value =
            _formatNumber(dashboardData['bibit_siap_tanam'] ?? 0);
        bibitButuhPerhatian.value =
            _formatNumber(dashboardData['butuh_perhatian'] ?? 0);
        bibitDipindai.value =
            _formatNumber(dashboardData['total_bibit_dipindai'] ?? 0);

        // Calculate growth if available
        if (dashboardData['previous_total_bibit'] != null &&
            dashboardData['previous_total_bibit'] > 0) {
          final current = dashboardData['total_bibit'] ?? 0;
          final previous = dashboardData['previous_total_bibit'] ?? 1;
          final growth = ((current - previous) / previous) * 100;
          pertumbuhanBibit.value = "${growth.toStringAsFixed(1)}%";
        } else {
          pertumbuhanBibit.value = "0%";
        }
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

// Tambahkan metode untuk refresh data secara manual
  Future<void> refreshDashboardData() async {
    if (currentUserId == null) return;

    try {
      // Clear dashboard cache first
      await _firebaseService.clearDashboardCache(currentUserId!);

      // Then fetch fresh data
      await fetchDashboardData();
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

  Future<void> fetchRecentActivities() async {
    if (currentUserId == null) return;

    try {
      // Fetch recent activities directly using our new function
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

      final activities = sortedDocs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Determine icon based on activity name
        IconData icon;
        String activityName = data['nama_aktivitas'] ?? '';

        if (activityName.toLowerCase().contains('scan')) {
          icon = Icons.qr_code_scanner_rounded;
        } else if (activityName.toLowerCase().contains('edit') ||
            activityName.toLowerCase().contains('pembaruan')) {
          icon = Icons.edit_rounded;
        } else if (activityName.toLowerCase().contains('cetak') ||
            activityName.toLowerCase().contains('print')) {
          icon = Icons.print_rounded;
        } else if (activityName.toLowerCase().contains('tambah') ||
            activityName.toLowerCase().contains('daftar') ||
            activityName.toLowerCase().contains('pendaftaran')) {
          icon = Icons.add_circle_outline_rounded;
        } else if (activityName.toLowerCase().contains('hapus')) {
          icon = Icons.delete_outline_rounded;
        } else {
          icon = Icons.article_rounded;
        }

        // Format time
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
          idUser: data['id_user'] ?? currentUserId!,
          namaAktivitas: data['nama_aktivitas'] ?? 'Aktivitas tidak diketahui',
          tipeObjek: data['tipe_objek'],
          idObjek: data['id_objek'],
          tanggalWaktu: timestamp ?? Timestamp.now(),
          createdAt: data['created_at'] as Timestamp? ?? Timestamp.now(),
          updatedAt: data['updated_at'] as Timestamp? ?? Timestamp.now(),
          icon: icon,
          time: timeString,
          highlight: sortedDocs.indexOf(doc) == 0, // Highlight first item
        );
      }).toList();

      recentActivities.assignAll(activities);
    } catch (e) {
      print('Error fetching activities: $e');
    }
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
        'icon': Icons.edit_note_rounded,
        'title': "Update Informasi Bibit",
        'onTap': () {
          closeMenu();
          navigateToUpdateBibit();
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

  // Tambahkan fungsi-fungsi ini ke PenyemaianDashboardController

// ====== STATISTIK DASHBOARD ======

// Update statistik dashboard berdasarkan data bibit terbaru
  Future<void> updateBibitStatistics() async {
    if (currentUserId == null) return;

    try {
      // Hitung statistik dari koleksi bibit
      QuerySnapshot bibitSnapshot = await FirebaseFirestore.instance
          .collection('bibit')
          .where('id_user', isEqualTo: currentUserId)
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

      // Hitung bibit yang dipindai
      int totalBibitDipindai = 0;
      for (var doc in bibitSnapshot.docs) {
        String bibitId = doc.id;

        QuerySnapshot historySnapshot = await FirebaseFirestore.instance
            .collection('bibit')
            .doc(bibitId)
            .collection('pengisian_history')
            .get();

        if (historySnapshot.docs.isNotEmpty) {
          totalBibitDipindai++;
        }
      }

      // Ambil data dashboard sebelumnya untuk pertumbuhan
      DocumentSnapshot dashboardDoc = await FirebaseFirestore.instance
          .collection('dashboard_informasi_admin_penyemaian')
          .doc(currentUserId)
          .get();

      int previousTotalBibit = 0;
      if (dashboardDoc.exists) {
        Map<String, dynamic> data = dashboardDoc.data() as Map<String, dynamic>;
        previousTotalBibit = data['total_bibit'] as int? ?? 0;
      }

      // Update dashboard statistik
      await FirebaseFirestore.instance
          .collection('dashboard_informasi_admin_penyemaian')
          .doc(currentUserId)
          .set({
        'total_bibit': totalBibit,
        'bibit_siap_tanam': bibitSiapTanam,
        'butuh_perhatian': butuhPerhatian,
        'total_bibit_dipindai': totalBibitDipindai,
        'previous_total_bibit': previousTotalBibit,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Refresh data dashboard di UI
      await fetchDashboardData();
    } catch (e) {
      print('Error updating bibit statistics: $e');
    }
  }

// ====== BIBIT CRUD ======

// Mendapatkan daftar bibit dengan paginasi
  Future<List<BibitModel>> getBibitList({
    int limit = 10,
    DocumentSnapshot? startAfter,
    String? searchQuery,
    String? filterKondisi,
  }) async {
    try {
      if (currentUserId == null) return [];

      Query query = FirebaseFirestore.instance
          .collection('bibit')
          .where('id_user', isEqualTo: currentUserId)
          .limit(limit);

      // Terapkan filter jika ada
      if (filterKondisi != null && filterKondisi.isNotEmpty) {
        query = query.where('kondisi', isEqualTo: filterKondisi);
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
      List<BibitModel> bibitList = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final BibitModel bibit = BibitModel.fromMap(doc.id, data);

            // Filter berdasarkan pencarian jika ada
            if (searchQuery != null && searchQuery.isNotEmpty) {
              final String namaBibit = bibit.namaBibit.toLowerCase();
              final String varietas = bibit.varietas.toLowerCase();
              final search = searchQuery.toLowerCase();

              if (!namaBibit.contains(search) && !varietas.contains(search)) {
                return null;
              }
            }
            return bibit;
          })
          .whereType<BibitModel>()
          .toList();

      return bibitList;
    } catch (e) {
      print('Error getting bibit list: $e');
      return [];
    }
  }

// Mendapatkan detail bibit berdasarkan ID
  Future<BibitModel?> getBibitDetail(String bibitId) async {
    try {
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('bibit')
          .doc(bibitId)
          .get();

      if (doc.exists) {
        return BibitModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting bibit detail: $e');
      return null;
    }
  }

// Menambahkan bibit baru
  Future<String?> addBibit(Map<String, dynamic> bibitData) async {
    try {
      if (currentUserId == null) return null;

      // Buat ID bibit baru
      final DocumentReference bibitRef =
          FirebaseFirestore.instance.collection('bibit').doc();

      // Tambahkan data bibit
      await bibitRef.set({
        'id_user': currentUserId,
        'nama_bibit': bibitData['nama_bibit'] ?? '',
        'varietas': bibitData['varietas'] ?? '',
        'usia': bibitData['usia'] ?? 0,
        'tinggi': bibitData['tinggi'] ?? 0.0,
        'jenis_bibit': bibitData['jenis_bibit'] ?? '',
        'kondisi': bibitData['kondisi'] ?? 'Baik',
        'status_hama': bibitData['status_hama'] ?? 'Tidak Ada',
        'media_tanam': bibitData['media_tanam'] ?? '',
        'nutrisi': bibitData['nutrisi'] ?? '',
        'asal_bibit': bibitData['asal_bibit'] ?? '',
        'produktivitas': bibitData['produktivitas'] ?? 0.0,
        'catatan': bibitData['catatan'] ?? '',
        'created_at': FieldValue.serverTimestamp(),
        'tanggal_pembibitan':
            bibitData['tanggal_pembibitan'] ?? Timestamp.now(),
        'gambar_image': bibitData['gambar_image'] ?? [],
        'barcode':
            'BT${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(10000)}',
        'url_bibit': 'https://yourapp.com/bibit/${bibitRef.id}',
        'lokasi_tanam': bibitData['lokasi_tanam'] ??
            {
              'lat': 0.0,
              'lng': 0.0,
              'alamat': '',
            },
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Rekam aktivitas
      await recordActivity(
          'Pendaftaran Bibit ${bibitData['nama_bibit']}', 'bibit', bibitRef.id);

      // Update statistik dashboard
      await updateBibitStatistics();

      return bibitRef.id;
    } catch (e) {
      print('Error adding bibit: $e');
      return null;
    }
  }

// Memperbarui data bibit
  Future<bool> updateBibit(
      String bibitId, Map<String, dynamic> bibitData) async {
    try {
      await FirebaseFirestore.instance.collection('bibit').doc(bibitId).update({
        'nama_bibit': bibitData['nama_bibit'],
        'varietas': bibitData['varietas'],
        'usia': bibitData['usia'],
        'tinggi': bibitData['tinggi'],
        'jenis_bibit': bibitData['jenis_bibit'],
        'kondisi': bibitData['kondisi'],
        'status_hama': bibitData['status_hama'],
        'media_tanam': bibitData['media_tanam'],
        'nutrisi': bibitData['nutrisi'],
        'asal_bibit': bibitData['asal_bibit'],
        'produktivitas': bibitData['produktivitas'],
        'catatan': bibitData['catatan'],
        'tanggal_pembibitan': bibitData['tanggal_pembibitan'],
        'gambar_image': bibitData['gambar_image'],
        'lokasi_tanam': bibitData['lokasi_tanam'],
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Rekam aktivitas
      await recordActivity(
          'Pembaruan Data Bibit ${bibitData['nama_bibit']}', 'bibit', bibitId);

      // Update statistik dashboard
      await updateBibitStatistics();

      return true;
    } catch (e) {
      print('Error updating bibit: $e');
      return false;
    }
  }

// Menghapus bibit
  Future<bool> deleteBibit(String bibitId, String namaBibit) async {
    try {
      // Dapatkan koleksi jadwal perawatan dan hapus
      QuerySnapshot careSchedules = await FirebaseFirestore.instance
          .collection('bibit')
          .doc(bibitId)
          .collection('jadwal_perawatan')
          .get();

      // Hapus semua jadwal perawatan
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in careSchedules.docs) {
        batch.delete(doc.reference);
      }

      // Dapatkan riwayat pengisian dan hapus
      QuerySnapshot histories = await FirebaseFirestore.instance
          .collection('bibit')
          .doc(bibitId)
          .collection('pengisian_history')
          .get();

      // Hapus semua riwayat
      for (var doc in histories.docs) {
        batch.delete(doc.reference);
      }

      // Hapus dokumen bibit
      batch.delete(FirebaseFirestore.instance.collection('bibit').doc(bibitId));

      // Commit batch delete
      await batch.commit();

      // Rekam aktivitas
      await recordActivity('Penghapusan Bibit $namaBibit', 'bibit', bibitId);

      // Update statistik dashboard
      await updateBibitStatistics();

      return true;
    } catch (e) {
      print('Error deleting bibit: $e');
      return false;
    }
  }

// Memindai barcode bibit
  Future<bool> scanBibit(String bibitId) async {
    try {
      if (currentUserId == null) return false;

      // Tambahkan riwayat pemindaian
      await FirebaseFirestore.instance
          .collection('bibit')
          .doc(bibitId)
          .collection('pengisian_history')
          .add({
        'id_user': currentUserId,
        'tanggal': Timestamp.now(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Ambil data bibit untuk aktivitas
      DocumentSnapshot bibitDoc = await FirebaseFirestore.instance
          .collection('bibit')
          .doc(bibitId)
          .get();

      if (bibitDoc.exists) {
        Map<String, dynamic> bibitData =
            bibitDoc.data() as Map<String, dynamic>;
        String namaBibit = bibitData['nama_bibit'] ?? 'Bibit';

        // Rekam aktivitas
        await recordActivity('Scan Barcode $namaBibit', 'bibit', bibitId);

        // Update statistik dashboard
        await updateBibitStatistics();

        return true;
      }

      return false;
    } catch (e) {
      print('Error scanning bibit: $e');
      return false;
    }
  }

// ====== JADWAL PERAWATAN CRUD ======

// Mendapatkan jadwal perawatan untuk bibit tertentu
  Future<List<CareScheduleModel>> getBibitCareSchedules(String bibitId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bibit')
          .doc(bibitId)
          .collection('jadwal_perawatan')
          .orderBy('jadwal')
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return CareScheduleModel.fromMap(doc.id, data);
      }).toList();
    } catch (e) {
      print('Error getting care schedules: $e');
      return [];
    }
  }

// Mendapatkan semua jadwal perawatan untuk user saat ini
  Future<List<CareScheduleModel>> getAllCareSchedules(
      {bool upcomingOnly = false}) async {
    try {
      if (currentUserId == null) return [];

      // Dapatkan semua bibit milik user ini
      QuerySnapshot bibitSnapshot = await FirebaseFirestore.instance
          .collection('bibit')
          .where('id_user', isEqualTo: currentUserId)
          .get();

      List<CareScheduleModel> allSchedules = [];
      final now = Timestamp.now();

      // Untuk setiap bibit, dapatkan jadwal perawatannya
      for (var bibitDoc in bibitSnapshot.docs) {
        final String bibitId = bibitDoc.id;
        final Map<String, dynamic> bibitData =
            bibitDoc.data() as Map<String, dynamic>;
        final String namaBibit = bibitData['nama_bibit'] ?? 'Bibit';
        final String varietas = bibitData['varietas'] ?? '';

        QuerySnapshot scheduleSnapshot = await FirebaseFirestore.instance
            .collection('bibit')
            .doc(bibitId)
            .collection('jadwal_perawatan')
            .orderBy('jadwal')
            .get();

        for (var scheduleDoc in scheduleSnapshot.docs) {
          Map<String, dynamic> scheduleData =
              scheduleDoc.data() as Map<String, dynamic>;

          // Filter jadwal yang akan datang jika diminta
          if (upcomingOnly) {
            Timestamp? scheduleTime = scheduleData['jadwal'] as Timestamp?;
            if (scheduleTime == null || scheduleTime.compareTo(now) < 0) {
              continue; // Lewati jadwal yang sudah lewat
            }
          }

          // Tambahkan info bibit ke jadwal perawatan
          CareScheduleModel schedule =
              CareScheduleModel.fromMap(scheduleDoc.id, {
            ...scheduleData,
            'bibitId': bibitId,
            'namaBibit': namaBibit,
            'varietas': varietas,
          });

          allSchedules.add(schedule);
        }
      }

      // Urutkan jadwal berdasarkan waktu
      allSchedules.sort((a, b) => a.jadwal.compareTo(b.jadwal));

      return allSchedules;
    } catch (e) {
      print('Error getting all care schedules: $e');
      return [];
    }
  }

// Menambahkan jadwal perawatan baru
  Future<String?> addCareSchedule(
      String bibitId, Map<String, dynamic> scheduleData) async {
    try {
      if (currentUserId == null) return null;

      // Referensi dokumen jadwal perawatan baru
      final DocumentReference scheduleRef = FirebaseFirestore.instance
          .collection('bibit')
          .doc(bibitId)
          .collection('jadwal_perawatan')
          .doc();

      // Tambahkan jadwal perawatan
      await scheduleRef.set({
        'id_user': currentUserId,
        'jadwal': scheduleData['jadwal'] ?? Timestamp.now(),
        'jenis_perawatan': scheduleData['jenis_perawatan'] ?? 'Penyiraman',
        'judul_perawatan':
            scheduleData['judul_perawatan'] ?? 'Jadwal Perawatan',
        'deskripsi': scheduleData['deskripsi'] ?? '',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Ambil data bibit untuk aktivitas
      DocumentSnapshot bibitDoc = await FirebaseFirestore.instance
          .collection('bibit')
          .doc(bibitId)
          .get();

      if (bibitDoc.exists) {
        Map<String, dynamic> bibitData =
            bibitDoc.data() as Map<String, dynamic>;
        String namaBibit = bibitData['nama_bibit'] ?? 'Bibit';

        // Rekam aktivitas
        await recordActivity(
            'Penambahan Jadwal ${scheduleData['jenis_perawatan']} untuk $namaBibit',
            'bibit',
            bibitId);
      }

      return scheduleRef.id;
    } catch (e) {
      print('Error adding care schedule: $e');
      return null;
    }
  }

// Memperbarui jadwal perawatan
  Future<bool> updateCareSchedule(String bibitId, String scheduleId,
      Map<String, dynamic> scheduleData) async {
    try {
      await FirebaseFirestore.instance
          .collection('bibit')
          .doc(bibitId)
          .collection('jadwal_perawatan')
          .doc(scheduleId)
          .update({
        'jadwal': scheduleData['jadwal'],
        'jenis_perawatan': scheduleData['jenis_perawatan'],
        'judul_perawatan': scheduleData['judul_perawatan'],
        'deskripsi': scheduleData['deskripsi'],
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Ambil data bibit untuk aktivitas
      DocumentSnapshot bibitDoc = await FirebaseFirestore.instance
          .collection('bibit')
          .doc(bibitId)
          .get();

      if (bibitDoc.exists) {
        Map<String, dynamic> bibitData =
            bibitDoc.data() as Map<String, dynamic>;
        String namaBibit = bibitData['nama_bibit'] ?? 'Bibit';

        // Rekam aktivitas
        await recordActivity(
            'Pembaruan Jadwal ${scheduleData['jenis_perawatan']} untuk $namaBibit',
            'bibit',
            bibitId);
      }

      return true;
    } catch (e) {
      print('Error updating care schedule: $e');
      return false;
    }
  }

// Menghapus jadwal perawatan
  Future<bool> deleteCareSchedule(String bibitId, String scheduleId) async {
    try {
      // Ambil data jadwal untuk aktivitas
      DocumentSnapshot scheduleDoc = await FirebaseFirestore.instance
          .collection('bibit')
          .doc(bibitId)
          .collection('jadwal_perawatan')
          .doc(scheduleId)
          .get();

      String jenisPerawatan = 'perawatan';
      if (scheduleDoc.exists) {
        Map<String, dynamic> scheduleData =
            scheduleDoc.data() as Map<String, dynamic>;
        jenisPerawatan =
            scheduleData['jenis_perawatan'] as String? ?? 'perawatan';
      }

      // Hapus jadwal
      await FirebaseFirestore.instance
          .collection('bibit')
          .doc(bibitId)
          .collection('jadwal_perawatan')
          .doc(scheduleId)
          .delete();

      // Ambil data bibit untuk aktivitas
      DocumentSnapshot bibitDoc = await FirebaseFirestore.instance
          .collection('bibit')
          .doc(bibitId)
          .get();

      if (bibitDoc.exists) {
        Map<String, dynamic> bibitData =
            bibitDoc.data() as Map<String, dynamic>;
        String namaBibit = bibitData['nama_bibit'] ?? 'Bibit';

        // Rekam aktivitas
        await recordActivity(
            'Penghapusan Jadwal $jenisPerawatan untuk $namaBibit',
            'bibit',
            bibitId);
      }

      return true;
    } catch (e) {
      print('Error deleting care schedule: $e');
      return false;
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

// Mendapatkan aktivitas untuk user saat ini
  Future<List<ActivityModel>> getActivities({int limit = 20}) async {
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

      // Convert to activities
      return sortedDocs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return ActivityModel.fromMap(doc.id, data);
      }).toList();
    } catch (e) {
      print('Error getting activities: $e');
      return [];
    }
  }

// ====== RIWAYAT PEMINDAIAN ======

// Mendapatkan riwayat pemindaian untuk bibit tertentu
  Future<List<ScanHistoryModel>> getBibitScanHistory(String bibitId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bibit')
          .doc(bibitId)
          .collection('pengisian_history')
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

// Mendapatkan semua riwayat pemindaian untuk user saat ini
  Future<List<Map<String, dynamic>>> getAllScanHistory({int limit = 50}) async {
    try {
      if (currentUserId == null) return [];

      // Dapatkan semua bibit milik user ini
      QuerySnapshot bibitSnapshot = await FirebaseFirestore.instance
          .collection('bibit')
          .where('id_user', isEqualTo: currentUserId)
          .get();

      List<Map<String, dynamic>> allScans = [];

      // Untuk setiap bibit, dapatkan riwayat pemindaian
      for (var bibitDoc in bibitSnapshot.docs) {
        final String bibitId = bibitDoc.id;
        final Map<String, dynamic> bibitData =
            bibitDoc.data() as Map<String, dynamic>;
        final String namaBibit = bibitData['nama_bibit'] ?? 'Bibit';
        final String varietas = bibitData['varietas'] ?? '';

        QuerySnapshot scanSnapshot = await FirebaseFirestore.instance
            .collection('bibit')
            .doc(bibitId)
            .collection('pengisian_history')
            .orderBy('tanggal', descending: true)
            .get();

        for (var scanDoc in scanSnapshot.docs) {
          Map<String, dynamic> scanData =
              scanDoc.data() as Map<String, dynamic>;
          allScans.add({
            'scanId': scanDoc.id,
            'bibitId': bibitId,
            'namaBibit': namaBibit,
            'varietas': varietas,
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
}

// Model untuk bibit
class BibitModel {
  final String id;
  final String idUser;
  final String namaBibit;
  final String varietas;
  final int usia;
  final double tinggi;
  final String jenisBibit;
  final String kondisi;
  final String statusHama;
  final String mediaTanam;
  final String nutrisi;
  final String asalBibit;
  final double produktivitas;
  final String catatan;
  final Timestamp createdAt;
  final Timestamp tanggalPembibitan;
  final List<String> gambarImage;
  final String barcode;
  final String urlBibit;
  final Map<String, dynamic> lokasiTanam;
  final Timestamp updatedAt;

  BibitModel({
    required this.id,
    required this.idUser,
    required this.namaBibit,
    required this.varietas,
    required this.usia,
    required this.tinggi,
    required this.jenisBibit,
    required this.kondisi,
    required this.statusHama,
    required this.mediaTanam,
    required this.nutrisi,
    required this.asalBibit,
    required this.produktivitas,
    required this.catatan,
    required this.createdAt,
    required this.tanggalPembibitan,
    required this.gambarImage,
    required this.barcode,
    required this.urlBibit,
    required this.lokasiTanam,
    required this.updatedAt,
  });

  factory BibitModel.fromMap(String id, Map<String, dynamic> data) {
    return BibitModel(
      id: id,
      idUser: data['id_user'] ?? '',
      namaBibit: data['nama_bibit'] ?? '',
      varietas: data['varietas'] ?? '',
      usia: data['usia'] ?? 0,
      tinggi: (data['tinggi'] is int)
          ? (data['tinggi'] as int).toDouble()
          : data['tinggi'] ?? 0.0,
      jenisBibit: data['jenis_bibit'] ?? '',
      kondisi: data['kondisi'] ?? 'Baik',
      statusHama: data['status_hama'] ?? 'Tidak Ada',
      mediaTanam: data['media_tanam'] ?? '',
      nutrisi: data['nutrisi'] ?? '',
      asalBibit: data['asal_bibit'] ?? '',
      produktivitas: (data['produktivitas'] is int)
          ? (data['produktivitas'] as int).toDouble()
          : data['produktivitas'] ?? 0.0,
      catatan: data['catatan'] ?? '',
      createdAt: data['created_at'] as Timestamp? ?? Timestamp.now(),
      tanggalPembibitan:
          data['tanggal_pembibitan'] as Timestamp? ?? Timestamp.now(),
      gambarImage: (data['gambar_image'] as List<dynamic>?)
              ?.map((item) => item.toString())
              ?.toList() ??
          [],
      barcode: data['barcode'] ?? '',
      urlBibit: data['url_bibit'] ?? '',
      lokasiTanam: data['lokasi_tanam'] as Map<String, dynamic>? ??
          {
            'lat': 0.0,
            'lng': 0.0,
            'alamat': '',
          },
      updatedAt: data['updated_at'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_user': idUser,
      'nama_bibit': namaBibit,
      'varietas': varietas,
      'usia': usia,
      'tinggi': tinggi,
      'jenis_bibit': jenisBibit,
      'kondisi': kondisi,
      'status_hama': statusHama,
      'media_tanam': mediaTanam,
      'nutrisi': nutrisi,
      'asal_bibit': asalBibit,
      'produktivitas': produktivitas,
      'catatan': catatan,
      'created_at': createdAt,
      'tanggal_pembibitan': tanggalPembibitan,
      'gambar_image': gambarImage,
      'barcode': barcode,
      'url_bibit': urlBibit,
      'lokasi_tanam': lokasiTanam,
      'updated_at': updatedAt,
    };
  }
}

// Model untuk jadwal perawatan bibit
class CareScheduleModel {
  final String id;
  final String idUser;
  final Timestamp jadwal;
  final String jenisPerawatan;
  final String judulPerawatan;
  final String deskripsi;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  // Data tambahan untuk tampilan
  final String? bibitId;
  final String? namaBibit;
  final String? varietas;

  CareScheduleModel({
    required this.id,
    required this.idUser,
    required this.jadwal,
    required this.jenisPerawatan,
    required this.judulPerawatan,
    required this.deskripsi,
    required this.createdAt,
    required this.updatedAt,
    this.bibitId,
    this.namaBibit,
    this.varietas,
  });

  factory CareScheduleModel.fromMap(String id, Map<String, dynamic> data) {
    return CareScheduleModel(
      id: id,
      idUser: data['id_user'] ?? '',
      jadwal: data['jadwal'] as Timestamp? ?? Timestamp.now(),
      jenisPerawatan: data['jenis_perawatan'] ?? '',
      judulPerawatan: data['judul_perawatan'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      createdAt: data['created_at'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updated_at'] as Timestamp? ?? Timestamp.now(),
      bibitId: data['bibitId'],
      namaBibit: data['namaBibit'],
      varietas: data['varietas'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_user': idUser,
      'jadwal': jadwal,
      'jenis_perawatan': jenisPerawatan,
      'judul_perawatan': judulPerawatan,
      'deskripsi': deskripsi,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

// Model untuk history pemindaian bibit
class ScanHistoryModel {
  final String id;
  final String idUser;
  final Timestamp tanggal;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  // Data tambahan untuk tampilan
  final String? bibitId;
  final String? namaBibit;
  final String? varietas;

  ScanHistoryModel({
    required this.id,
    required this.idUser,
    required this.tanggal,
    required this.createdAt,
    required this.updatedAt,
    this.bibitId,
    this.namaBibit,
    this.varietas,
  });

  factory ScanHistoryModel.fromMap(String id, Map<String, dynamic> data) {
    return ScanHistoryModel(
      id: id,
      idUser: data['id_user'] ?? '',
      tanggal: data['tanggal'] as Timestamp? ?? Timestamp.now(),
      createdAt: data['created_at'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updated_at'] as Timestamp? ?? Timestamp.now(),
      bibitId: data['bibitId'],
      namaBibit: data['namaBibit'],
      varietas: data['varietas'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_user': idUser,
      'tanggal': tanggal,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

// Model untuk aktivitas
class ActivityModel {
  final String id;
  final String idUser;
  final String namaAktivitas;
  final String? tipeObjek;
  final String? idObjek;
  final Timestamp tanggalWaktu;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  // UI properties
  final IconData? icon;
  final String? time;
  final bool highlight;

  ActivityModel({
    required this.id,
    required this.idUser,
    required this.namaAktivitas,
    this.tipeObjek,
    this.idObjek,
    required this.tanggalWaktu,
    required this.createdAt,
    required this.updatedAt,
    this.icon,
    this.time,
    this.highlight = false,
  });

  factory ActivityModel.fromMap(String id, Map<String, dynamic> data) {
    return ActivityModel(
      id: id,
      idUser: data['id_user'] ?? '',
      namaAktivitas: data['nama_aktivitas'] ?? '',
      tipeObjek: data['tipe_objek'],
      idObjek: data['id_objek'],
      tanggalWaktu: data['tanggal_waktu'] as Timestamp? ?? Timestamp.now(),
      createdAt: data['created_at'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updated_at'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_user': idUser,
      'nama_aktivitas': namaAktivitas,
      'tipe_objek': tipeObjek,
      'id_objek': idObjek,
      'tanggal_waktu': tanggalWaktu,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

// Model untuk pengguna
class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? photoUrl;
  final Timestamp? lastLogin;
  final String? kodeOtp;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.photoUrl,
    this.lastLogin,
    this.kodeOtp,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Menentukan role
    UserRole userRole = UserRole.adminPenyemaian; // Default
    List<dynamic> roles = data['role'] as List<dynamic>? ?? [];
    if (roles.contains('admin_tpk')) {
      userRole = UserRole.adminTPK;
    }

    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['nama_lengkap'] ?? '',
      role: userRole,
      photoUrl: data['photo_url'],
      lastLogin: data['last_login'] as Timestamp?,
      kodeOtp: data['kode_otp'],
      createdAt: data['created_at'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updated_at'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.toString(),
      'photoUrl': photoUrl,
      'lastLogin': lastLogin?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'] == 'UserRole.adminTPK'
          ? UserRole.adminTPK
          : UserRole.adminPenyemaian,
      photoUrl: json['photoUrl'],
      lastLogin: json['lastLogin'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(json['lastLogin'])
          : null,
      createdAt: Timestamp.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: Timestamp.fromMillisecondsSinceEpoch(json['updatedAt']),
    );
  }
}

// Enum untuk role pengguna
enum UserRole {
  adminPenyemaian,
  adminTPK,
}
