import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/dashboard_tpk/dashboard_tpk_controller.dart';
import 'package:flutter_green_track/controllers/navigation/navigation_controller.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/dashboard_tpk_page.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/widget/widget_dashboard.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

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
            TextButton(
              onPressed: () {
                // Show all actions in modal sheet
                _showAllActions(controller.actions);
              },
              child: Text(
                "Lihat Semua",
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF4CAF50),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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

        // Activity items from controller
        Obx(() {
          if (controller.recentActivities.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Belum ada aktivitas terbaru",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            );
          }

          return Column(
            children: controller.recentActivities
                .take(3) // Show only 3 most recent activities
                .map((activity) => ActivityItemWidget(
                      icon: activity.icon!,
                      title: activity.namaAktivitas,
                      time: activity.time ?? '',
                      highlight: activity.highlight,
                    ))
                .toList(),
          );
        }),

        // View all button
        Center(
          child: TextButton(
            onPressed: () =>
                {controller.navigationController.navigateToAktivitasTPK()},
            child: Text(
              "Lihat Semua",
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
