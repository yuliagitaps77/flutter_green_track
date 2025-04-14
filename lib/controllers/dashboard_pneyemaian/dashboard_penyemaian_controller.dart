import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';
import 'package:flutter_green_track/data/models/user_model.dart';
import 'package:flutter_green_track/service/services.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../fitur/dashboard_penyemaian/repository/penyemaian_repository.dart';
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
      // Get current user from local storage
      final user = await _firebaseService.getLocalUser();
      if (user != null) {
        currentUserId = user.id;

        // Update user profile with actual user data
        userProfile.value = UserProfileModel(
          name:
              user.name, // Menggunakan nama user yang sebenarnya dari Firestore
          role: user.role == UserRole.adminPenyemaian
              ? "Admin Penyemaian"
              : "Admin TPK",
          photoUrl: user.photoUrl,
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
              role: userData.role == UserRole.adminPenyemaian
                  ? "Admin Penyemaian"
                  : "Admin TPK",
              photoUrl: userData.photoUrl,
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
  }

  void navigateToPrintBarcode() {
    print('Navigating to Print Barcode page');
    // Get.toNamed('/print-barcode');
  }

  void navigateToDaftarBibit() {
    print('Navigating to Plant List page');
    // Get.toNamed('/daftar-bibit');
  }

  void navigateToJadwalRawat() {
    print('Navigating to Care Schedule page');
    // Get.toNamed('/jadwal-rawat');
    // Get.to(PlantCareScheduleScreen());
  }

  void navigateToRiwayatScan() {
    print('Navigating to Scan History page');
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
  Future<void> fetchDashboardData() async {
    if (currentUserId == null) return;

    isLoading.value = true;
    try {
      // Fetch dashboard data from Firestore
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
      // Fetch recent activities from Firestore
      final activities =
          await _firebaseService.getRecentActivities(currentUserId!);

      if (activities.isNotEmpty) {
        final activityModels = activities.map((activity) {
          // Determine icon based on activity type
          IconData icon;
          switch (activity['nama_aktivitas']) {
            case 'scan':
              icon = Icons.qr_code_scanner_rounded;
              break;
            case 'edit':
              icon = Icons.edit_rounded;
              break;
            case 'print':
              icon = Icons.print_rounded;
              break;
            case 'add':
              icon = Icons.add_circle_outline_rounded;
              break;
            default:
              icon = Icons.article_rounded;
          }

          // Format time
          final timestamp = activity['tanggal_waktu'] as Timestamp?;
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
            icon: icon,
            title: activity['nama_aktivitas'] ?? 'Aktivitas tidak diketahui',
            time: timeString,
            highlight:
                activities.indexOf(activity) == 0, // Highlight first item
          );
        }).toList();

        recentActivities.assignAll(activityModels);
      }
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
}
