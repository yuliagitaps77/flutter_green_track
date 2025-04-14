import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../fitur/dashboard_penyemaian/repository/penyemaian_repository.dart';
import '../../fitur/dashboard_tpk/model/model_dashboard_tpk.dart';

class PenyemaianDashboardController extends GetxController {
  final PenyemaianRepository repository = PenyemaianRepository();

  // Loading state
  RxBool isLoading = false.obs;

  // User profile data
  Rx<UserProfileModel> userProfile = UserProfileModel(
          name: "Yulia Gita A", role: "Admin Penyemaian", photoUrl: "")
      .obs;

  // Statistics data
  RxString totalBibit = "1,245".obs;
  RxString bibitSiapTanam = "482".obs;
  RxString bibitButuhPerhatian = "23".obs;
  RxString bibitDipindai = "87".obs;
  RxString pertumbuhanBibit = "+15%".obs;
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

  @override
  void onInit() {
    super.onInit();
    initActions();
    fetchDashboardData();
    fetchRecentActivities();
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

  // Navigation methods
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
    // Implement logout logic here
    print('Logging out...');
    // Perform logout actions
    // Get.offAllNamed('/login');
  }

  // Handle view all activities
  void viewAllActivities() {
    print('Viewing all activities');
    // Get.toNamed('/activities');
  }

  // Data fetching methods
  Future<void> fetchDashboardData() async {
    isLoading.value = true;
    try {
      // In a real app, these would be API calls
      await Future.delayed(Duration(milliseconds: 800));

      // Mock data - in a real app you would fetch this from your API
      totalBibit.value = "1,245";
      bibitSiapTanam.value = "482";
      bibitButuhPerhatian.value = "23";
      bibitDipindai.value = "87";
      pertumbuhanBibit.value = "+15%";

      // Update chart data if needed
      updateChartData();
    } catch (e) {
      print('Error fetching dashboard data: $e');
      // Handle error appropriately
    } finally {
      isLoading.value = false;
    }
  }

  void updateChartData() {
    // This would update the chart data from backend
    // For now, we'll use the static data defined in the constructor
  }

  Future<void> fetchRecentActivities() async {
    try {
      // In a real app, this would be an API call
      await Future.delayed(Duration(milliseconds: 500));

      // Mock data
      recentActivities.assignAll([
        ActivityModel(
          icon: Icons.qr_code_scanner_rounded,
          title: "Scan Barcode Bibit Mahoni",
          time: "Baru saja",
          highlight: true,
        ),
        ActivityModel(
          icon: Icons.edit_rounded,
          title: "Pembaruan Data Bibit Jati",
          time: "2 jam yang lalu",
          highlight: false,
        ),
        ActivityModel(
          icon: Icons.print_rounded,
          title: "Pencetakan 25 Barcode",
          time: "Kemarin, 16:30",
          highlight: false,
        ),
        ActivityModel(
          icon: Icons.add_circle_outline_rounded,
          title: "Pendaftaran 30 Bibit Baru",
          time: "Kemarin, 14:15",
          highlight: false,
        ),
      ]);
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
          // Handle change password
        },
      },
      {
        'icon': Icons.logout_rounded,
        'title': "Logout",
        'isDestructive': true,
        'onTap': () {
          closeMenu();
          // Show logout confirmation
          logout();
        },
      },
    ];
  }
}
