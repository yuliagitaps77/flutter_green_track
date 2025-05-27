import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';
import 'package:flutter_green_track/controllers/navigation/navigation_controller.dart';
import 'package:flutter_green_track/fitur/authentication/update_profile_screen.dart';
import 'package:flutter_green_track/fitur/dashboard_penyemaian/page_penyemaian_jadwal_perawatan.dart';
import 'package:flutter_green_track/service/services.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'dart:async';

import '../../fitur/dashboard_penyemaian/page_cetak_bibit.dart';
import '../../fitur/dashboard_tpk/model/model_dashboard_tpk.dart';
import '../../fitur/navigation/penyemaian/model/model_bibit.dart';
import '../../fitur/navigation/penyemaian/controller/controller_page_nav_bibit.dart';
import '../../fitur/lacak_history/user_activity_model.dart';

class PenyemaianDashboardController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final BibitController bibitController = Get.find<BibitController>();
  final AuthenticationController authController =
      Get.find<AuthenticationController>();
  final AppController appController = Get.find<AppController>();

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
  RxString bibitMasukBulanIni = "0".obs;
  RxString bibitMasukTrend = "Bulan ini".obs;
  RxString scanStatTrend = "Minggu ini".obs;

  // Chart data
  final RxList<FlSpot> bibitMasukSpots = <FlSpot>[].obs;
  final RxString totalBibitMasuk = "0".obs;

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

  // Observable values
  final averageHeight = "0".obs;
  final highestGrowth = "0.0".obs;
  final lowestGrowth = "0.0".obs;
  final totalMeasurements = "0".obs;

  // Firestore subscription
  StreamSubscription<QuerySnapshot>? _bibitSubscription;
  Timer? _debounceTimer;

  // Add new subscription for activities
  StreamSubscription<QuerySnapshot>? _activitiesSubscription;

  @override
  void onInit() {
    super.onInit();
    initActions();
    initUserData();
    fetchGrowthData();
    _setupBibitListener();
    _setupActivitiesListener();
  }

  @override
  void onClose() {
    _bibitSubscription?.cancel();
    _activitiesSubscription?.cancel();
    _debounceTimer?.cancel();
    super.onClose();
  }

  void _setupBibitListener() {
    // Listen to Firestore changes
    _bibitSubscription = FirebaseFirestore.instance
        .collection('bibit')
        .snapshots()
        .listen((snapshot) {
      print('🔄 Bibit collection changed, refreshing dashboard data...');
      _debouncedRefresh();
    });
  }

  void _setupActivitiesListener() {
    print('🔄 [ACTIVITIES] Setting up real-time listener...');
    _activitiesSubscription?.cancel();

    final currentUser = authController.currentUser.value;
    if (currentUser == null) return;

    _activitiesSubscription = FirebaseFirestore.instance
        .collection('aktivitas')
        .where('id_user', isEqualTo: currentUser.id)
        .where('nama_aktivitas', isEqualTo: 'Scan Barcode')
        .snapshots()
        .listen((snapshot) {
      print('📡 [ACTIVITIES] Received real-time update');
      _processActivitiesSnapshot(snapshot);
    }, onError: (error) {
      print('❌ [ACTIVITIES] Error in real-time listener: $error');
    });
  }

  void _processActivitiesSnapshot(QuerySnapshot snapshot) {
    print(
        '🔄 [ACTIVITIES] Processing snapshot with ${snapshot.docs.length} documents');
    try {
      // Update local activities list
      final activities = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserActivity(
          id: doc.id,
          userId: data['id_user'] ?? '',
          activityType: ActivityTypes.scanBarcode,
          timestamp:
              (data['tanggal_waktu'] as Timestamp?)?.toDate() ?? DateTime.now(),
          description: data['nama_aktivitas'] ?? '',
          userRole: 'admin_penyemaian',
        );
      }).toList();

      // Update appController's activities
      appController.recentActivities.value = activities;

      // Recalculate statistics
      calculateScanningStatistics();
      print('✅ [ACTIVITIES] Activities processed and statistics updated');
    } catch (e) {
      print('❌ [ACTIVITIES] Error processing activities: $e');
    }
  }

  void _debouncedRefresh() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      refreshDashboardData();
    });
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
    navigationController.navigateToHistory();
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

  Future<void> refreshUserProfileData() async {
    try {
      print('Refreshing user profile data...');

      // Get fresh user data from Firestore
      if (currentUserId != null) {
        final userData = await _firebaseService.getUserData(currentUserId!);

        if (userData != null) {
          print(
              'Fresh user data retrieved: ${userData.name}, Photo: ${userData.photoUrl}');

          // Update the userProfile value with new data
          userProfile.value = UserProfileModel(
            name: userData.name,
            role: userData.role == UserRole.adminPenyemaian
                ? "Admin Penyemaian"
                : "Admin TPK",
            photoUrl: userData.photoUrl ?? '',
          );
        }
      } else {
        print('Cannot refresh user data: currentUserId is null');
      }
    } catch (e) {
      print('Error refreshing user profile data: $e');
    }
  }

  void handleProfileTap() async {
    // Navigate to profile page
    await Get.toNamed(ProfileUpdateScreen.routeName);

    // When user returns from the profile page, refresh the profile data
    refreshUserProfileData();
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
          bibitMasukTrend.value = "${growth.toStringAsFixed(1)}%";
        } else {
          bibitMasukTrend.value = "0%";
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

  Future<void> refreshDashboardData() async {
    await calculateBibitMasukStatistics();
    await calculateScanningStatistics();
    await calculateBibitStatistics();
  }

  Future<void> calculateBibitMasukStatistics() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Get bibit created in current month
      final bibitThisMonth = bibitController.bibitList
          .where((bibit) =>
              bibit.createdAt != null && bibit.createdAt!.isAfter(startOfMonth))
          .toList();

      // Count total bibit masuk this month
      totalBibitMasuk.value = bibitThisMonth.length.toString();

      // Group bibit by day for the chart
      final Map<int, int> dailyCount = {};
      for (var bibit in bibitThisMonth) {
        final day = bibit.createdAt!.day;
        dailyCount[day] = (dailyCount[day] ?? 0) + 1;
      }

      // Create spots for chart (last 7 days)
      final spots = <FlSpot>[];
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final count = dailyCount[date.day] ?? 0;
        spots.add(FlSpot(6 - i.toDouble(), count.toDouble()));
      }

      bibitMasukSpots.value = spots;
      bibitMasukTrend.value = "Bulan ini";
    } catch (e) {
      print('Error calculating bibit masuk statistics: $e');
    }
  }

  Future<void> calculateScanningStatistics() async {
    try {
      print('🔄 [SCAN] Calculating scanning statistics...');
      final currentUser = authController.currentUser.value;
      if (currentUser == null) {
        print('❌ [SCAN] No current user found');
        return;
      }

      // Get scan activities for current user
      List<UserActivity> scanActivities = appController.recentActivities
          .where((activity) =>
              activity.userId == currentUser.id &&
              activity.activityType == ActivityTypes.scanBarcode)
          .toList();

      print('📊 [SCAN] Found ${scanActivities.length} scan activities');

      // Update total scans with proper formatting
      bibitDipindai.value = _formatNumber(scanActivities.length);

      // Calculate trend for last 7 days
      int recentScans = scanActivities
          .where((activity) =>
              activity.timestamp != null &&
              activity.timestamp!
                  .isAfter(DateTime.now().subtract(Duration(days: 7))))
          .length;
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
      for (var activity in scanActivities) {
        if (activity.timestamp != null) {
          DateTime date = DateTime(
            activity.timestamp!.year,
            activity.timestamp!.month,
            activity.timestamp!.day,
          );
          if (date.isAfter(now.subtract(Duration(days: 7)))) {
            scansByDate[date] = (scansByDate[date] ?? 0) + 1;
          }
        }
      }

      // Convert to spots
      List<FlSpot> spots = [];
      List<DateTime> sortedDates = scansByDate.keys.toList()..sort();
      for (int i = 0; i < sortedDates.length; i++) {
        spots.add(
            FlSpot(i.toDouble(), scansByDate[sortedDates[i]]?.toDouble() ?? 0));
      }
      scannedSpots.value = spots;

      // Update Firestore dashboard data
      final dashboardRef = FirebaseFirestore.instance
          .collection('dashboard_penyemaian')
          .doc(currentUser.id);

      try {
        // First check if document exists
        final docSnapshot = await dashboardRef.get();

        if (!docSnapshot.exists) {
          // Create new document with initial data
          await dashboardRef.set({
            'total_bibit_dipindai': scanActivities.length,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
            'user_id': currentUser.id,
            'total_bibit': 0,
            'bibit_siap_tanam': 0,
            'butuh_perhatian': 0,
          });
          print(
              '✅ [SCAN] Created new dashboard document for user ${currentUser.id}');
        } else {
          // Update existing document
          await dashboardRef.update({
            'total_bibit_dipindai': scanActivities.length,
            'updated_at': FieldValue.serverTimestamp(),
          });
          print(
              '✅ [SCAN] Updated existing dashboard document for user ${currentUser.id}');
        }
      } catch (e) {
        print('❌ [SCAN] Error updating Firestore: $e');
        // Don't throw the error, just log it and continue
      }

      print('✅ [SCAN] Scanning statistics updated successfully');
    } catch (e) {
      print('❌ [SCAN] Error calculating scanning statistics: $e');
      // Set default values in case of error
      bibitDipindai.value = "0";
      scanStatTrend.value = "0 pemindaian minggu ini";
      scannedSpots.value = List.generate(7, (i) => FlSpot(i.toDouble(), 0));
    }
  }

  Future<void> calculateBibitStatistics() async {
    try {
      await bibitController.fetchBibitFromFirestore();
      List<Bibit> allBibit = bibitController.bibitList;

      totalBibit.value = allBibit.length.toString();

      int siapTanam = allBibit
          .where((b) => b.tinggi >= 30 && b.kondisi.toLowerCase() == 'baik')
          .length;
      bibitSiapTanam.value = siapTanam.toString();

      int butuhPerhatian = allBibit
          .where((b) =>
              b.kondisi.toLowerCase() != 'baik' ||
              b.statusHama.toLowerCase() != 'tidak ada')
          .length;
      bibitButuhPerhatian.value = butuhPerhatian.toString();
    } catch (e) {
      print('Error calculating bibit statistics: $e');
    }
  }

  // Get filtered scan history
  List<UserActivity> getScanHistory(String period) {
    final currentUser = authController.currentUser.value;
    if (currentUser == null) return [];

    DateTime startDate;
    switch (period) {
      case '1 Bulan':
        startDate = DateTime.now().subtract(Duration(days: 30));
        break;
      case '3 Bulan':
        startDate = DateTime.now().subtract(Duration(days: 90));
        break;
      case '6 Bulan':
        startDate = DateTime.now().subtract(Duration(days: 180));
        break;
      case '1 Tahun':
        startDate = DateTime.now().subtract(Duration(days: 365));
        break;
      default:
        startDate = DateTime.now().subtract(Duration(days: 180));
    }

    return appController.recentActivities
        .where((activity) =>
            activity.userId == currentUser.id &&
            activity.activityType == ActivityTypes.scanBarcode &&
            activity.timestamp.isAfter(startDate))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
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
            activityName.contains('pendaftaran')) {
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
        'title': "Update Akun",
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

  // Method untuk mengambil data pertumbuhan bibit
  Future<void> fetchGrowthData() async {
    try {
      print('\n🌱 Memulai fetchGrowthData...');

      print('🔍 Querying Firestore collection: bibit');
      final QuerySnapshot bibitSnapshot = await FirebaseFirestore.instance
          .collection('bibit')
          .orderBy('tanggal_pembibitan')
          .get();

      print('📊 Query results:');
      print('- Total documents: ${bibitSnapshot.docs.length}');

      // Print sample of the first document if exists
      if (bibitSnapshot.docs.isNotEmpty) {
        final sampleDoc = bibitSnapshot.docs.first;
        final data = sampleDoc.data() as Map<String, dynamic>;
        print('\n📄 Sample document structure:');
        print('Document ID: ${sampleDoc.id}');
        data.forEach((key, value) {
          print('$key: $value (${value.runtimeType})');
        });
      }

      if (bibitSnapshot.docs.isEmpty) {
        print('⚠️ Tidak ada data bibit, menggunakan nilai default');
        bibitMasukSpots.assignAll([
          FlSpot(0, 0),
          FlSpot(1, 0),
        ]);
        bibitMasukTrend.value = "0%";
        return;
      }

      Map<int, List<double>> heightsByMonth = {};
      DateTime firstDate = DateTime.now();

      // Debug data bibit
      print('\n🔍 Analyzing bibit data:');
      for (var doc in bibitSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('\n📝 Document ID: ${doc.id}');
        print('Tinggi: ${data['tinggi']}');
        print(
            'Tanggal Pembibitan: ${(data['tanggal_pembibitan'] as Timestamp?)?.toDate()}');

        final tinggi = (data['tinggi'] ?? 0).toDouble();
        final tanggalPembibitan = data['tanggal_pembibitan'] as Timestamp?;

        if (tanggalPembibitan == null) {
          print('⚠️ Tanggal pembibitan null untuk bibit ${doc.id}');
          continue;
        }

        final tanggalPembibitanDate = tanggalPembibitan.toDate();

        if (tanggalPembibitanDate.isBefore(firstDate)) {
          firstDate = tanggalPembibitanDate;
        }

        // Hitung selisih bulan dari tanggal pertama
        int monthDiff = (tanggalPembibitanDate.year - firstDate.year) * 12 +
            tanggalPembibitanDate.month -
            firstDate.month;

        print(
            '📅 Month diff: $monthDiff (${tanggalPembibitanDate.toString()} - ${firstDate.toString()})');
        print('📏 Tinggi: $tinggi cm');

        if (!heightsByMonth.containsKey(monthDiff)) {
          heightsByMonth[monthDiff] = [];
        }
        heightsByMonth[monthDiff]!.add(tinggi);
      }

      print('\n📊 Data tinggi per bulan:');
      heightsByMonth.forEach((month, heights) {
        print('Bulan $month: ${heights.length} data, heights: $heights');
      });

      // Pastikan ada data untuk setiap bulan
      if (heightsByMonth.isNotEmpty) {
        int maxMonth = heightsByMonth.keys.reduce(math.max);
        print('\n🔄 Interpolating missing months from 0 to $maxMonth');

        for (int i = 0; i <= maxMonth; i++) {
          if (!heightsByMonth.containsKey(i)) {
            int prevMonth = i - 1;
            int nextMonth = i + 1;
            while (!heightsByMonth.containsKey(prevMonth) && prevMonth >= 0)
              prevMonth--;
            while (!heightsByMonth.containsKey(nextMonth) &&
                nextMonth <= maxMonth) nextMonth++;

            if (prevMonth >= 0 && nextMonth <= maxMonth) {
              double prevHeight =
                  heightsByMonth[prevMonth]!.reduce((a, b) => a + b) /
                      heightsByMonth[prevMonth]!.length;
              double nextHeight =
                  heightsByMonth[nextMonth]!.reduce((a, b) => a + b) /
                      heightsByMonth[nextMonth]!.length;
              double interpolatedHeight = prevHeight +
                  (nextHeight - prevHeight) *
                      (i - prevMonth) /
                      (nextMonth - prevMonth);
              heightsByMonth[i] = [interpolatedHeight];
              print(
                  '📈 Interpolated month $i: $interpolatedHeight (between $prevMonth and $nextMonth)');
            }
          }
        }
      }

      // Buat spots untuk grafik
      List<FlSpot> spots = [];
      heightsByMonth.forEach((month, heights) {
        if (heights.isNotEmpty) {
          double averageHeight =
              heights.reduce((a, b) => a + b) / heights.length;
          spots.add(FlSpot(month.toDouble(), averageHeight));
        }
      });

      // Urutkan berdasarkan bulan
      spots.sort((a, b) => a.x.compareTo(b.x));

      print('\n📊 Final spots data:');
      spots.forEach((spot) => print('Month: ${spot.x}, Height: ${spot.y}'));

      // Pastikan minimal ada 2 titik
      if (spots.length < 2) {
        print('⚠️ Kurang dari 2 titik data, menambahkan titik tambahan');
        if (spots.isEmpty) {
          spots = [FlSpot(0, 0), FlSpot(1, 0)];
        } else {
          spots.add(FlSpot(spots[0].x + 1, spots[0].y));
        }
      }

      // Hitung pertumbuhan rata-rata
      if (spots.length > 1) {
        double totalGrowth = spots.last.y - spots.first.y;
        double monthsPassed = spots.last.x - spots.first.x;
        double averageGrowthPerMonth =
            monthsPassed > 0 ? totalGrowth / monthsPassed : 0;
        bibitMasukTrend.value = "${averageGrowthPerMonth.toStringAsFixed(1)}%";
        print('\n📈 Pertumbuhan rata-rata: ${bibitMasukTrend.value}');
      } else {
        bibitMasukTrend.value = "0%";
      }

      print('\n✅ Assigning ${spots.length} spots to bibitMasukSpots');
      bibitMasukSpots.assignAll(spots);
    } catch (e, stackTrace) {
      print('❌ Error in fetchGrowthData: $e');
      print('Stack trace: $stackTrace');
      bibitMasukSpots.assignAll([FlSpot(0, 0), FlSpot(1, 0)]);
      bibitMasukTrend.value = "0%";
    }
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
