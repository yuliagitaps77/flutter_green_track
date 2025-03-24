import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/dashboard_tpk/dashboard_tpk_controller.dart';
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

  // Data for charts
  final List<FlSpot> inventorySpots = [
    FlSpot(0, 10),
    FlSpot(1, 14),
    FlSpot(2, 18),
    FlSpot(3, 15),
    FlSpot(4, 20),
    FlSpot(5, 16),
    FlSpot(6, 22),
  ];

  final List<FlSpot> revenueSpots = [
    FlSpot(0, 5),
    FlSpot(1, 8),
    FlSpot(2, 10),
    FlSpot(3, 15),
    FlSpot(4, 18),
    FlSpot(5, 14),
    FlSpot(6, 20),
  ];

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
                AppBarWidget(
                  onMenuTap: () => _menuAnimController.forward(),
                  onProfileTap: () {
                    // Handle profile tap
                  },
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
                          GreetingWidget(
                            name: "Fitri Meydayani",
                            role: "Admin TPK",
                            description:
                                "Kelola inventori kayu dan jadwal pengiriman dengan mudah!",
                          ),

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

          // Floating Action Button

          // Menu overlay
          SideMenuWidget(
            name: "Fitri Meydayani",
            role: "Admin TPK",
            menuItems: _getMenuItems(),
            menuAnimation: _menuAnimation,
            onClose: () => _menuAnimController.reverse(),
          ),
        ],
      ),
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
              style: TextStyle(
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
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 15),

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
                return ActionCardWidget(
                  icon: action['icon'],
                  title: action['title'],
                  onTap: action['onTap'],
                  highlight: action['highlight'] ?? false,
                  breathingAnimation: _breathingAnimation,
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
                      return ActionCardWidget(
                        icon: action['icon'],
                        title: action['title'],
                        onTap: () {
                          Get.back();
                          action['onTap']();
                        },
                        highlight: action['highlight'] ?? false,
                        breathingAnimation: _breathingAnimation,
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

  // Sh
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
              child: StatCardWidget(
                title: "Inventory Kayu",
                value: "876",
                trend: "Minggu ini",
                icon: Icons.inventory_2_rounded,
                spots: inventorySpots,
                color: Color(0xFF4CAF50),
                breathingAnimation: _breathingAnimation,
              ),
            ),
            SizedBox(width: 15),
            // Revenue Card
            Expanded(
              child: StatCardWidget(
                title: "Kayui Dipindai",
                value: "87",
                trend: "Bulan ini",
                icon: Icons.qr_code_scanner_rounded,
                spots: revenueSpots,
                color: Color(0xFF66BB6A),
                breathingAnimation: _breathingAnimation,
              ),
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
              SummaryItemWidget(
                icon: Icons.inventory_2_rounded,
                title: "Total Kayu",
                value: "876",
                color: Color(0xFF4CAF50),
              ),
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

        // Activity items - TPK specific activities
        ActivityItemWidget(
          icon: Icons.qr_code_scanner_rounded,
          title: "Scan Barcode Kayu Jati",
          time: "Baru saja",
          highlight: true,
        ),

        ActivityItemWidget(
          icon: Icons.inventory_2_rounded,
          title: "Update Stok Kayu",
          time: "Kemarin, 16:30",
        ),
        ActivityItemWidget(
          icon: Icons.assignment_rounded,
          title: "Laporan Bulanan Dibuat",
          time: "Kemarin, 14:15",
        ),

        // View all button
        Center(
          child: TextButton(
            onPressed: () {
              // Handle view all activities
            },
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

  // Get menu items for side menu
  List<Map<String, dynamic>> _getMenuItems() {
    return [
      {
        'icon': Icons.dashboard_rounded,
        'title': "Dashboard",
        'isActive': true,
        'onTap': () {
          _menuAnimController.reverse();
        },
      },
      {
        'icon': Icons.settings_rounded,
        'title': "Pengaturan",
        'onTap': () {
          _menuAnimController.reverse();
          // Handle settings
        },
      },
      {
        'icon': Icons.lock_outline_rounded,
        'title': "Ubah Kata Sandi",
        'onTap': () {
          _menuAnimController.reverse();
          // Handle change password
        },
      },
      {
        'icon': Icons.logout_rounded,
        'title': "Logout",
        'isDestructive': true,
        'onTap': () {
          _menuAnimController.reverse();
          showLogoutConfirmation(context);
        },
      },
    ];
  }
}
