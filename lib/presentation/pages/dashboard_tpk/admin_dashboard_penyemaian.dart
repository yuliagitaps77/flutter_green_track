import 'package:flutter/material.dart';
import 'package:flutter_green_track/presentation/pages/dashboard_tpk/dashboard_tpk_page.dart';
import 'package:flutter_green_track/presentation/pages/dashboard_tpk/widget/widget_dashboard.dart';
import 'package:flutter_green_track/presentation/pages/jadwal_perawatan/jadwal_perawatan_page.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

// Import shared widgets

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

  final List<FlSpot> growthSpots = [
    FlSpot(0, 2.5),
    FlSpot(1, 3.1),
    FlSpot(2, 3.6),
    FlSpot(3, 4.2),
    FlSpot(4, 4.5),
    FlSpot(5, 5.3),
    FlSpot(6, 5.9),
  ];

  final List<FlSpot> scannedSpots = [
    FlSpot(0, 5),
    FlSpot(1, 12),
    FlSpot(2, 8),
    FlSpot(3, 18),
    FlSpot(4, 10),
    FlSpot(5, 15),
    FlSpot(6, 20),
  ];

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
                            name: "Yulia Gita",
                            role: "Admin Penyemaian",
                            description:
                                "Pantau perkembangan tanaman dan kelola informasi bibit dengan mudah!",
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

          // Menu overlay
          SideMenuWidget(
            name: "Yulia Gita",
            role: "Admin Penyemaian",
            menuItems: _getMenuItems(),
            menuAnimation: _menuAnimation,
            onClose: () => _menuAnimController.reverse(),
          ),
        ],
      ),
    );
  }

  // Quick actions section
 Widget _buildQuickActions() {
  // List of actions for Penyemaian Admin
  List<Map<String, dynamic>> actions = [
    {
      'icon': Icons.qr_code_scanner_rounded,
      'title': 'Scan\nBarcode',
      'onTap': () {
        // Handle scan barcode
      },
      'highlight': true, // Highlight main action
    },
    {
      'icon': Icons.print_rounded,
      'title': 'Cetak\nBarcode',
      'onTap': () {
        // Handle print barcode
      },
    },
    {
      'icon': Icons.forest_rounded,
      'title': 'Daftar\nBibit',
      'onTap': () {
        // Handle view plants list
      },
    },
    {
      'icon': Icons.calendar_month_rounded,
      'title': 'Jadwal\nRawat',
      'onTap': () {
        Get.to(PlantCareScheduleScreen());
      },
    },
    {
      'icon': Icons.history,
      'title': 'Riwayat\nScan',
      'onTap': () {
        // Handle plant care
      },
    },
    {
      'icon': Icons.analytics_rounded,
      'title': 'Laporan\nBulanan',
      'onTap': () {
        // Handle scan history
      },
    }
  ];

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
              _showAllActions(actions);
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

      // Grid layout for action cards - Improved to handle varying text lengths
      GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 items per row
          childAspectRatio: 1.0, // Adjusted aspect ratio for better text fit
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: math.min(6, actions.length), // Max 6 items on dashboard
        itemBuilder: (context, index) {
          final action = actions[index];
          return MouseRegion(
            onEnter: (_) {
              setState(() {
                action['highlight'] = true; // Highlight the icon when hovered
              });
            },
            onExit: (_) {
              setState(() {
                action['highlight'] = false; // Remove highlight when mouse exits
              });
            },
            child: ActionCardWidget(
              icon: action['icon'],
              title: action['title'],
              onTap: action['onTap'],
              highlight: action['highlight'] ?? false,
              breathingAnimation: _breathingAnimation,
            ),
          );
        },
      ),
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
              child: GridView.builder(
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
              ),
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
              child: StatCardWidget(
                title: "Pertumbuhan Bibit",
                value: "+15%",
                trend: "Bulan ini",
                icon: Icons.trending_up_rounded,
                spots: growthSpots,
                color: Color(0xFF4CAF50),
                breathingAnimation: _breathingAnimation,
              ),
            ),
            SizedBox(width: 15),
            // Scanned Plants Card
            Expanded(
              child: StatCardWidget(
                title: "Bibit Dipindai",
                value: "87",
                trend: "Minggu ini",
                icon: Icons.qr_code_scanner_rounded,
                spots: scannedSpots,
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
                icon: Icons.forest_rounded,
                title: "Total Bibit",
                value: "1,245",
                color: Color(0xFF4CAF50),
              ),
              Divider(height: 20),
              SummaryItemWidget(
                icon: Icons.nature_people_rounded,
                title: "Bibit Siap Tanam",
                value: "482",
                color: Color(0xFF66BB6A),
              ),
              Divider(height: 20),
              SummaryItemWidget(
                icon: Icons.notifications_rounded,
                title: "Butuh Perhatian",
                value: "23",
                color: Color(0xFFFF9800),
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

        // Activity items
        ActivityItemWidget(
          icon: Icons.qr_code_scanner_rounded,
          title: "Scan Barcode Bibit Mahoni",
          time: "Baru saja",
          highlight: true,
        ),
        ActivityItemWidget(
          icon: Icons.edit_rounded,
          title: "Pembaruan Data Bibit Jati",
          time: "2 jam yang lalu",
        ),
        ActivityItemWidget(
          icon: Icons.print_rounded,
          title: "Pencetakan 25 Barcode",
          time: "Kemarin, 16:30",
        ),
        ActivityItemWidget(
          icon: Icons.add_circle_outline_rounded,
          title: "Pendaftaran 30 Bibit Baru",
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
        'icon': Icons.edit_note_rounded,
        'title': "Update Informasi Bibit",
        'onTap': () {
          _menuAnimController.reverse();
          // Handle update plant info
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
