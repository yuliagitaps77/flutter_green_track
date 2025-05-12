import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';
import 'package:flutter_green_track/controllers/dashboard_tpk/dashboard_tpk_controller.dart';
import 'package:flutter_green_track/controllers/navigation/navigation_controller.dart';
import 'package:flutter_green_track/fitur/dashboard_penyemaian/admin_dashboard_penyemaian.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/dashboard_tpk_page.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/widget/widget_dashboard.dart';
import 'package:flutter_green_track/fitur/lacak_history/activity_history_screen.dart';
import 'package:flutter_green_track/fitur/lacak_history/user_activity_model.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

import 'package:intl/intl.dart';

// Import shared widgets

class TPKDashboardScreen extends StatefulWidget {
  const TPKDashboardScreen({Key? key}) : super(key: key);
  static String? routeName = "/TPKDashboardScreen";

  @override
  _TPKDashboardScreenState createState() => _TPKDashboardScreenState();
}

class _TPKDashboardScreenState extends State<TPKDashboardScreen>
    with TickerProviderStateMixin {
  // Controllers for animations
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  late AnimationController _menuAnimController;
  late Animation<double> _menuAnimation;

  // Controller for TPK Dashboard
  final TPKDashboardController controller = Get.put(TPKDashboardController());
  final navigationController = Get.find<NavigationController>();

  @override
  void initState() {
    super.initState();

    // Initialize breathing animation controller
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

    // Listen to menu state changes from controller
    ever(controller.isMenuOpen, (bool isOpen) {
      if (isOpen && _menuAnimController.status != AnimationStatus.completed) {
        _menuAnimController.forward();
      } else if (!isOpen &&
          _menuAnimController.status != AnimationStatus.dismissed) {
        _menuAnimController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _menuAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => Stack(
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
                    AppBarWidget(
                      onMenuTap: () => controller.toggleMenu(),
                      onProfileTap: () => controller.handleProfileTap(),
                    ),

                    // Dashboard content
                    Expanded(
                      child: controller.isLoading.value
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF4CAF50)))
                          : SingleChildScrollView(
                              physics: BouncingScrollPhysics(),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 20),

                                    // Greeting section - using user profile from controller
                                    Obx(() => GreetingWidget(
                                          name:
                                              controller.userProfile.value.name,
                                          role:
                                              controller.userProfile.value.role,
                                          description:
                                              "Kelola inventori kayu dan jadwal pengiriman dengan mudah!",
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

              // Menu overlay using controller's menu items
              Obx(() => SideMenuWidget(
                    name: controller.userProfile.value.name,
                    role: controller.userProfile.value.role,
                    photoProfile: controller.userProfile.value.photoUrl,
                    menuItems: controller.getMenuItems(),
                    menuAnimation: _menuAnimation,
                    onClose: () => _menuAnimController.reverse(),
                  )),
            ],
          )),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Aksi Cepat",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
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
            //       color: const Color(0xFF4CAF50),
            //       fontWeight: FontWeight.w500,
            //     ),
            //   ),
            // ),
          ],
        ),
        const SizedBox(height: 15),

        // Grid layout for action cards - menggunakan Obx untuk reaktivitas
        Obx(() => GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 items per row
                childAspectRatio: 1.0, // Adjusted for better text fitting
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

  // Statistics section (specific to Admin TPK)
  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Statistik",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        SizedBox(height: 15),
        Row(
          children: [
            // Inventory Card
            Expanded(
              child: Obx(() => StatCardWidget(
                    title: "Inventory Kayu",
                    value: controller.totalWood.value,
                    trend: controller.woodStatTrend.value,
                    icon: Icons.inventory_2_rounded,
                    spots: controller.inventorySpots,
                    color: Color(0xFF4CAF50),
                    breathingAnimation: _breathingAnimation,
                  )),
            ),
            SizedBox(width: 15),
            // Scanned Wood Card
            Expanded(
              child: Obx(() => StatCardWidget(
                    title: "Kayu Dipindai",
                    value: controller.scannedWood.value,
                    trend: controller.scanStatTrend.value,
                    icon: Icons.qr_code_scanner_rounded,
                    spots: controller.revenueSpots,
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
                    icon: Icons.inventory_2_rounded,
                    title: "Total Kayu",
                    value: controller.totalWood.value,
                    color: Color(0xFF4CAF50),
                  )),
              SizedBox(height: 10),
              Obx(() => SummaryItemWidget(
                    icon: Icons.fact_check_rounded,
                    title: "Total Batch",
                    value: controller.totalBatch.value,
                    color: Color(0xFF66BB6A),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  // Recent activities section
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

  // Recent activities section
  final appController = Get.find<AppController>();

  final AuthenticationController authController =
      Get.find<AuthenticationController>();

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
