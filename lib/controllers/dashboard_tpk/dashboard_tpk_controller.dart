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
              role: userData.role == UserRole.adminTPK
                  ? "Admin TPK"
                  : "Admin Penyemaian",
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
      // Fetch dashboard data from Firestore
      final dashboardData = await _getTPKDashboardData(currentUserId!);

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

  // Helper function to get TPK dashboard data
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
          String activityName = activity['nama_aktivitas'] ?? '';

          if (activityName.toLowerCase().contains('scan')) {
            icon = Icons.qr_code_scanner_rounded;
          } else if (activityName.toLowerCase().contains('update')) {
            icon = Icons.edit_rounded;
          } else if (activityName.toLowerCase().contains('cetak') ||
              activityName.toLowerCase().contains('print')) {
            icon = Icons.print_rounded;
          } else if (activityName.toLowerCase().contains('tambah') ||
              activityName.toLowerCase().contains('daftar')) {
            icon = Icons.add_circle_outline_rounded;
          } else if (activityName.toLowerCase().contains('laporan')) {
            icon = Icons.assessment_rounded;
          } else if (activityName.toLowerCase().contains('kirim')) {
            icon = Icons.local_shipping_rounded;
          } else {
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
            title:
                activityName != '' ? activityName : 'Aktivitas tidak diketahui',
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
