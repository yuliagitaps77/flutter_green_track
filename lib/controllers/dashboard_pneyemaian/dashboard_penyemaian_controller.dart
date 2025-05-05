import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';
import 'package:flutter_green_track/controllers/navigation/navigation_controller.dart';
import 'package:flutter_green_track/fitur/dashboard_penyemaian/page_penyemaian_jadwal_perawatan.dart';
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
    Get.to(JadwalPerawatanPage());
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

// ====== BIBIT CRUD ======

// Menambahkan bibit baru

// ====== RIWAYAT PEMINDAIAN ======
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
