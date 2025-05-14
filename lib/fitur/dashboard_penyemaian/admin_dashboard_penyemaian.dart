import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';
import 'package:flutter_green_track/controllers/navigation/navigation_controller.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/widget/widget_dashboard.dart';
import 'package:flutter_green_track/fitur/lacak_history/activity_history_screen.dart';
import 'package:flutter_green_track/fitur/lacak_history/user_activity_model.dart';
import 'package:flutter_green_track/fitur/navigation/navigation_page.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/controller/controller_page_nav_bibit.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

import 'package:intl/intl.dart';

class PenyemaianDashboardScreen extends StatefulWidget {
  static String? routeName = "/PagePenyemaianDashboardScreen";

  const PenyemaianDashboardScreen({Key? key}) : super(key: key);

  @override
  _PenyemaianDashboardScreenState createState() =>
      _PenyemaianDashboardScreenState();
}

class _PenyemaianDashboardScreenState extends State<PenyemaianDashboardScreen>
    with TickerProviderStateMixin {
  // Controllers for animations
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late AnimationController _menuAnimController;
  late Animation<double> _menuAnimation;

  // Controller for Penyemaian Dashboard
  final BibitController bibitController = Get.put(BibitController());
  final PenyemaianDashboardController controller =
      Get.put(PenyemaianDashboardController());

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );

    // Controller for menu animation
    _menuAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _menuAnimation = CurvedAnimation(
      parent: _menuAnimController,
      curve: Curves.easeOut,
    );
  }

  final navigationController = Get.find<NavigationController>();
  @override
  void dispose() {
    _breathingController.dispose();
    _menuAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appController.syncActivitiesFromFirestore();
    });
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFF5F9F5),
                  Color(0xFFEDF7ED),
                ],
              ),
            ),
          ),

          // Dashboard content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App bar with menu and profile
                GestureDetector(
                  onTap: () {
                    controller.refreshDashboardData();
                  },
                  child: AppBarWidget(
                    onMenuTap: () => _menuAnimController.forward(),
                    onProfileTap: () => controller.handleProfileTap(),
                  ),
                ),

                // Dashboard content
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20),

                          // Greeting section
                          Obx(() => GreetingWidget(
                                name: controller.userProfile.value.name,
                                role: controller.userProfile.value.role,
                                description:
                                    "Pantau perkembangan tanaman dan kelola informasi bibit dengan mudah!",
                              )),

                          SizedBox(height: 25),

                          // Quick action cards
                          _buildQuickActions(),

                          SizedBox(height: 25),

                          // Statistics section
                          _buildStatisticsSection(),

                          SizedBox(height: 20),

                          // Recent activities
                          _buildRecentActivities(),

                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Menu overlay
          Obx(() => SideMenuWidget(
                name: controller.userProfile.value.name,
                role: controller.userProfile.value.role,
                photoProfile: controller.userProfile.value.photoUrl,
                menuItems: controller.getMenuItems(),
                menuAnimation: _menuAnimation,
                onClose: () => _menuAnimController.reverse(),
              )),
        ],
      ),
    );
  }

  // Quick actions section
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {},
              child: Text(
                "Aksi Cepat",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            // Button to view all actions
            // TextButton(
            //   onPressed: () {
            //     // Show all actions in modal sheet
            //     _showAllActions(controller.actions);
            //   },
            //   child: Text(
            //     "Lihat Semua",
            //     style: TextStyle(
            //       fontSize: 14,
            //       color: Color(0xFF4CAF50),
            //       fontWeight: FontWeight.w500,
            //     ),
            //   ),
            // ),
          ],
        ),
        SizedBox(height: 15),

        // Grid layout for action cards - Using Obx for reactivity
        Obx(() => GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 items per row
                childAspectRatio:
                    1.0, // Adjusted aspect ratio for better text fit
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: math.min(
                  6, controller.actions.length), // Max 6 items on dashboard
              itemBuilder: (context, index) {
                final action = controller.actions[index];
                return MouseRegion(
                  onEnter: (_) => controller.handleHover(index, true),
                  onExit: (_) => controller.handleHover(index, false),
                  child: ActionCardWidget(
                    icon: action['icon'],
                    title: action['title'],
                    onTap: action['onTap'],
                    highlight: action['highlight'] ?? false,
                    breathingAnimation: _breathingAnimation,
                  ),
                );
              },
            )),
      ],
    );
  }

  // Show all actions in bottom sheet
  void _showAllActions(List<Map<String, dynamic>> actions) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Semua Aksi",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.close),
                  color: Colors.grey[600],
                ),
              ],
            ),
            SizedBox(height: 15),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(Get.context!).size.height * 0.5,
              ),
              child: Obx(() => GridView.builder(
                    shrinkWrap: true,
                    physics: BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: actions.length,
                    itemBuilder: (context, index) {
                      final action = actions[index];
                      return MouseRegion(
                        onEnter: (_) => controller.handleHover(index, true),
                        onExit: (_) => controller.handleHover(index, false),
                        child: ActionCardWidget(
                          icon: action['icon'],
                          title: action['title'],
                          onTap: () {
                            Get.back();
                            action['onTap']();
                          },
                          highlight: action['highlight'] ?? false,
                          breathingAnimation: _breathingAnimation,
                        ),
                      );
                    },
                  )),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // Statistics section (specific to Admin Penyemaian)
  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Statistik",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to statistics detail page
                Get.toNamed('/statistics-detail');
              },
              child: Row(
                children: [
                  Text(
                    "Lihat Detail",
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color(0xFF4CAF50),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1, // Make it square
          children: [
            // Plant Growth Card replaced with Incoming Plants Card
            GestureDetector(
              onTap: () =>
                  Get.toNamed('/statistics-detail', arguments: 'incoming'),
              child: Obx(() => StatCardWidget(
                    title: "Bibit Masuk",
                    value: controller.totalBibitMasuk.value,
                    trend: controller.bibitMasukTrend.value,
                    icon: Icons.add_circle_outline_rounded,
                    spots: controller.bibitMasukSpots,
                    color: Color(0xFF4CAF50),
                    breathingAnimation: _breathingAnimation,
                  )),
            ),
            // Scanned Plants Card
            GestureDetector(
              onTap: () =>
                  Get.toNamed('/statistics-detail', arguments: 'scanned'),
              child: Obx(() => StatCardWidget(
                    title: "Bibit Dipindai",
                    value: controller.bibitDipindai.value,
                    trend: controller.scanStatTrend.value,
                    icon: Icons.qr_code_scanner_rounded,
                    spots: controller.scannedSpots,
                    color: Color(0xFF66BB6A),
                    breathingAnimation: _breathingAnimation,
                  )),
            ),
          ],
        ),
        SizedBox(height: 15),
        // Summary cards
        Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Obx(() => SummaryItemWidget(
                    icon: Icons.forest_rounded,
                    title: "Total Bibit",
                    value: controller.totalBibit.value,
                    color: Color(0xFF4CAF50),
                  )),
              Divider(height: 20),
              Obx(() => SummaryItemWidget(
                    icon: Icons.nature_people_rounded,
                    title: "Bibit Siap Tanam",
                    value: controller.bibitSiapTanam.value,
                    color: Color(0xFF66BB6A),
                  )),
              Divider(height: 20),
              Obx(() => SummaryItemWidget(
                    icon: Icons.notifications_rounded,
                    title: "Bibit Rusak",
                    value: controller.bibitButuhPerhatian.value,
                    color: Color(0xFFFF9800),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  // Recent activities section
  final appController = Get.find<AppController>();

  final AuthenticationController authController =
      Get.find<AuthenticationController>();
// Helper method to convert icon string to IconData
  IconData _getIconData(String? iconString) {
    if (iconString == null) return Icons.history;

    switch (iconString) {
      // Global activities
      case 'Icons.login_rounded':
        return Icons.login_rounded;
      case 'Icons.logout_rounded':
        return Icons.logout_rounded;
      case 'Icons.person_rounded':
        return Icons.person_rounded;
      case 'Icons.password_rounded':
        return Icons.password_rounded;

      // Admin Penyemaian activities
      case 'Icons.qr_code_scanner_rounded':
        return Icons.qr_code_scanner_rounded;
      case 'Icons.print_rounded':
        return Icons.print_rounded;
      case 'Icons.edit':
        return Icons.edit;
      case 'Icons.delete':
        return Icons.delete;
      case 'Icons.calendar_month_rounded':
        return Icons.calendar_month_rounded;

      // Jadwal Rawat icons
      case 'Icons.water_drop_rounded':
        return Icons.water_drop_rounded;
      case 'Icons.compost_rounded':
        return Icons.compost_rounded;
      case 'Icons.fact_check_rounded':
        return Icons.fact_check_rounded;
      case 'Icons.grass_rounded':
        return Icons.grass_rounded;
      case 'Icons.sanitizer_rounded':
        return Icons.sanitizer_rounded;
      case 'Icons.content_cut_rounded':
        return Icons.content_cut_rounded;
      case 'Icons.edit_calendar_rounded':
        return Icons.edit_calendar_rounded;
      case 'Icons.task_alt_rounded':
        return Icons.task_alt_rounded;
      case 'Icons.event_busy_rounded':
        return Icons.event_busy_rounded;

      // Admin TPK activities
      case 'Icons.forest_rounded':
        return Icons.forest_rounded;
      case 'Icons.local_shipping_rounded':
        return Icons.local_shipping_rounded;
      case 'Icons.add_circle_outline_rounded':
        return Icons.add_circle_outline_rounded;

      default:
        return Icons.history;
    }
  }

// Helper method to format timestamp
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final activityDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (activityDate == today) {
      return 'Hari ini, ${DateFormat('HH:mm').format(timestamp)}';
    } else if (activityDate == yesterday) {
      return 'Kemarin, ${DateFormat('HH:mm').format(timestamp)}';
    } else {
      return DateFormat('dd MMM, HH:mm').format(timestamp);
    }
  }

// Modified to highlight ONLY scanBarcode for Penyemaian and scanPohon for TPK
  bool _isHighlightActivity(String activityType, UserRole userRole) {
    if (userRole == UserRole.adminPenyemaian) {
      // HANYA highlight scanBarcode untuk Admin Penyemaian
      return activityType == ActivityTypes.scanBarcode;
    } else if (userRole == UserRole.adminTPK) {
      // HANYA highlight scanPohon untuk Admin TPK
      return activityType == ActivityTypes.scanPohon;
    }
    return false;
  }

// Recent activities section - updated to show user's own activities
  Widget _buildRecentActivities() {
    final userRole =
        authController.currentUser.value?.role ?? UserRole.adminPenyemaian;
    // Menggunakan warna hijau untuk kedua role
    final themeColor = Color(0xFF2E7D32); // Green for both Penyemaian and TPK

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Aktivitas Terbaru",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: themeColor,
          ),
        ),
        SizedBox(height: 15),

        // Use AppController's recentActivities with Obx for reactivity
        Obx(() {
          // Get user ID
          final userId = authController.currentUser.value?.id;
          if (userId == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Login untuk melihat aktivitas",
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            );
          }

          // Get activities based on role but filter for current user only
          List<UserActivity> activities;
          if (userRole == UserRole.adminPenyemaian) {
            activities = appController
                .getPenyemaianActivities(limit: 5)
                .where((activity) => activity.userId == userId)
                .toList();
          } else {
            activities = appController
                .getTPKActivities(limit: 5)
                .where((activity) => activity.userId == userId)
                .toList();
          }

          if (activities.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Belum ada aktivitas terbaru",
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            );
          }

          return Column(
            children: activities.map((activity) {
              // Convert UserActivity to format expected by ActivityItemWidget
              return ActivityItemWidget(
                icon: _getIconData(activity.icon),
                title: activity.description,
                time: _formatTimestamp(activity.timestamp),
                highlight:
                    _isHighlightActivity(activity.activityType, userRole),
              );
            }).toList(),
          );
        }),

        // View all button - updated to use HistoryNavigator
        Center(
          child: TextButton(
            onPressed: () => HistoryNavigator.goToHistoryPage(context),
            child: Text(
              "Lihat Semua",
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

extension DashboardIntegration on AppController {
  // Get activities relevant to Penyemaian dashboard
  List<UserActivity> getPenyemaianActivities({int limit = 5}) {
    // Define activity types specifically for Admin Penyemaian
    final penyemaianActivityTypes = [
      // Bibit management
      ActivityTypes.scanBarcode,
      ActivityTypes.printBarcode,
      ActivityTypes.updateBibit,
      ActivityTypes.deleteBibit,

      // Jadwal Rawat activities
      ActivityTypes.addJadwalRawat,
      ActivityTypes.addJadwalPenyiraman,
      ActivityTypes.addJadwalPemupukan,
      ActivityTypes.addJadwalPengecekan,
      ActivityTypes.addJadwalPenyiangan,
      ActivityTypes.addJadwalPenyemprotan,
      ActivityTypes.addJadwalPemangkasan,
      ActivityTypes.updateJadwalRawat,
      ActivityTypes.completeJadwalRawat,
      ActivityTypes.deleteJadwalRawat,
    ];

    // Filter activities by types relevant to Admin Penyemaian
    final filteredActivities = recentActivities
        .where((activity) =>
            penyemaianActivityTypes.contains(activity.activityType) ||
            // Include global activities when user role matches Admin Penyemaian
            ((activity.activityType == ActivityTypes.userLogin ||
                    activity.activityType == ActivityTypes.userLogout ||
                    activity.activityType == ActivityTypes.updateUserProfile ||
                    activity.activityType == ActivityTypes.changePassword) &&
                activity.userRole == 'AdminPenyemaian'))
        .take(limit)
        .toList();

    return filteredActivities;
  }

  // Get activities relevant to TPK dashboard
  List<UserActivity> getTPKActivities({int limit = 5}) {
    // Define activity types specifically for Admin TPK
    final tpkActivityTypes = [
      ActivityTypes.scanPohon,
      ActivityTypes.addKayu,
      ActivityTypes.updateKayu,
      ActivityTypes.deleteKayu,
    ];

    // Filter activities by types relevant to Admin TPK
    return recentActivities
        .where((activity) =>
            tpkActivityTypes.contains(activity.activityType) ||
            // Include global activities when user role matches Admin TPK
            ((activity.activityType == ActivityTypes.userLogin ||
                    activity.activityType == ActivityTypes.userLogout ||
                    activity.activityType == ActivityTypes.updateUserProfile ||
                    activity.activityType == ActivityTypes.changePassword) &&
                activity.userRole == 'AdminTPK'))
        .take(limit)
        .toList();
  }

  // Get all relevant activities for current user based on role
  List<UserActivity> getCurrentUserRoleActivities({int limit = 10}) {
    if (currentUser.value == null) return [];

    final userRole = currentUser.value!.role.toString();

    if (userRole == 'AdminPenyemaian') {
      return getPenyemaianActivities(limit: limit);
    } else if (userRole == 'AdminTPK') {
      return getTPKActivities(limit: limit);
    } else {
      // For other roles or fallback, just return recent activities
      return getRecentActivities(limit: limit);
    }
  }
}

// This function would normally be in a separate file
void showLogoutConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Konfirmasi Logout"),
        content: Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
            },
            child: Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // Handle logout
              // Get.offAllNamed('/login');
            },
            child: Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );
}
