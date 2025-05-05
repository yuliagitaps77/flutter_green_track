import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';
import 'package:flutter_green_track/controllers/navigation/navigation_controller.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/widget/widget_dashboard.dart';
import 'package:flutter_green_track/fitur/lacak_history/activity_history_screen.dart';
import 'package:flutter_green_track/fitur/lacak_history/user_activity_model.dart';
import 'package:flutter_green_track/fitur/navigation/navigation_page.dart';
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
              onTap: () {
                AppController.to.recordActivity(
                  activityType: ActivityTypes.scanBarcode,
                  description: 'Scan barcode bibit: asdd',
                  targetId: "12313",
                  metadata: {
                    'barcode': "hello world",
                    'timestamp': DateTime.now().toString(),
                  },
                );
              },
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
            TextButton(
              onPressed: () {
                // Show all actions in modal sheet
                _showAllActions(controller.actions);
              },
              child: Text(
                "Lihat Semua",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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
            // Plant Growth Card
            Expanded(
              child: Obx(() => StatCardWidget(
                    title: "Pertumbuhan Bibit",
                    value: controller.pertumbuhanBibit.value,
                    trend: controller.growthStatTrend.value,
                    icon: Icons.trending_up_rounded,
                    spots: controller.growthSpots,
                    color: Color(0xFF4CAF50),
                    breathingAnimation: _breathingAnimation,
                  )),
            ),
            SizedBox(width: 15),
            // Scanned Plants Card
            Expanded(
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
                    title: "Butuh Perhatian",
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

  // The rest of the screen implementation...

  // Modified recent activities section to use AppController
  bool _isHighlightActivity(String activityType) {
    // Highlight aktivitas yang dianggap penting
    return [
      ActivityTypes.scanBarcode,
      ActivityTypes.printBarcode,
    ].contains(activityType);
  }

  // Recent activities section
  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Aktivitas Terbaru",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        SizedBox(height: 15),

        // Use AppController's recentActivities with Obx for reactivity
        Obx(() {
          // Get activities relevant to Penyemaian admin
          final activities = appController.getPenyemaianActivities(limit: 5);

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
                highlight: _isHighlightActivity(activity.activityType),
              );
            }).toList(),
          );
        }),

        // View all button
        Center(
          child: TextButton(
            onPressed: () => Get.to(() => ActivityHistoryScreen()),
            child: Text(
              "Lihat Semua",
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to convert icon string to IconData
  IconData _getIconData(String? iconString) {
    if (iconString == null) return Icons.history;

    switch (iconString) {
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
      case 'Icons.forest_rounded':
        return Icons.forest_rounded;
      case 'Icons.local_shipping_rounded':
        return Icons.local_shipping_rounded;
      default:
        return Icons.history;
    }
  }

  // Helper method to format timestamp
  String _formatTimestamp(DateTime timestamp) {
    // For today's activities, show only time
    final now = DateTime.now();
    if (timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day) {
      return DateFormat('HH:mm').format(timestamp);
    }
    // For older activities, show date
    return DateFormat('dd MMM, HH:mm').format(timestamp);
  }
}

extension DashboardIntegration on AppController {
  // Get activities relevant to Penyemaian dashboard
  List<UserActivity> getPenyemaianActivities({int limit = 5}) {
    final penyemaianActivityTypes = [
      ActivityTypes.scanBarcode,
      ActivityTypes.printBarcode,
      ActivityTypes.updateBibit,
      ActivityTypes.deleteBibit,
      ActivityTypes.addJadwalRawat,
    ];

    // Filter activities by types relevant to Penyemaian
    final filteredActivities = recentActivities
        .where((activity) =>
            penyemaianActivityTypes.contains(activity.activityType))
        .take(limit)
        .toList();

    return filteredActivities;
  }

  // Get activities relevant to TPK dashboard
  List<UserActivity> getTPKActivities({int limit = 5}) {
    // Filter for activities relevant to TPK admin
    final relevantTypes = [
      ActivityTypes.scanBarcode,
      ActivityTypes.updateKayu,
      ActivityTypes.deleteKayu,
      ActivityTypes.addPengiriman,
    ];

    return recentActivities
        .where((activity) => relevantTypes.contains(activity.activityType))
        .take(limit)
        .toList();
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
