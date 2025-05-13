import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';
import 'package:flutter_green_track/fitur/authentication/update_profile_screen.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_green_track/fitur/authentication/LoginScreen.dart';

// Common widgets shared between both dashboard types

class AppBarWidget extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onProfileTap;

  const AppBarWidget(
      {Key? key, required this.onMenuTap, required this.onProfileTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Menu button
          GestureDetector(
            onTap: onMenuTap,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.menu_rounded,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
            ),
          ),

          // App logo and title
          Row(
            children: [
              Icon(
                Icons.eco_outlined,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                "Green Track",
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),

          // Profile button
          GestureDetector(
            onTap: () {
              Get.toNamed(ProfileUpdateScreen.routeName);
            },
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GreetingWidget extends StatelessWidget {
  final String name;
  final String role;
  final String? description;
  final AuthenticationController _authController =
      Get.find<AuthenticationController>();

  GreetingWidget(
      {Key? key, required this.name, required this.role, this.description})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use Obx here to listen to changes in the AuthenticationController
    return Obx(() {
      // Get the latest user data from the central AuthenticationController
      final currentUser = _authController.currentUser.value;

      // Use the provided name/role as fallbacks, but prefer the latest data from AuthController if available
      final userName = currentUser?.name ?? name;
      final userRole = currentUser != null
          ? (currentUser.role == UserRole.adminPenyemaian
              ? "Admin Penyemaian"
              : "Admin TPK")
          : role;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Selamat Datang,",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 5),
          Row(
            children: [
              Flexible(
                child: Text(
                  userName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(0xFF4CAF50).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  userRole,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
          if (description != null) ...[
            SizedBox(height: 10),
            Text(
              description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      );
    });
  }
}

class ActionCardWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool highlight;
  final Animation<double> breathingAnimation;

  const ActionCardWidget({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.highlight = false,
    required this.breathingAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: breathingAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: highlight
                  ? Color(0xFF4CAF50)
                      .withOpacity(0.08 * breathingAnimation.value)
                  : Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: highlight
                      ? Color(0xFF4CAF50)
                          .withOpacity(0.15 * breathingAnimation.value)
                      : Colors.black
                          .withOpacity(0.05 * breathingAnimation.value),
                  blurRadius: 8 * breathingAnimation.value,
                  offset: Offset(0, 3),
                  spreadRadius:
                      highlight ? 1 * (breathingAnimation.value - 0.92) * 5 : 0,
                ),
              ],
              border: Border.all(
                color: highlight
                    ? Color(0xFF4CAF50).withOpacity(0.3)
                    : Color(0xFF4CAF50).withOpacity(0.1),
                width: highlight ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icon container
                TweenAnimationBuilder(
                  duration: Duration(milliseconds: 300),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: highlight
                              ? Color(0xFF4CAF50)
                                  .withOpacity(0.15 * breathingAnimation.value)
                              : Color(0xFF4CAF50).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color:
                              highlight ? Color(0xFF2E7D32) : Color(0xFF4CAF50),
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 8),
                // Title text - Fixed to prevent overflow
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
                      color: highlight ? Color(0xFF2E7D32) : Color(0xFF424242),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StatCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final List<FlSpot> spots;
  final Color color;
  final Animation<double> breathingAnimation;

  const StatCardWidget({
    Key? key,
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.spots,
    required this.color,
    required this.breathingAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: breathingAnimation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15 * breathingAnimation.value),
                blurRadius: 10 * breathingAnimation.value,
                offset: Offset(0, 3),
                spreadRadius: 1 * (breathingAnimation.value - 0.92) * 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    icon,
                    size: 16,
                    color: color,
                  ),
                ],
              ),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 10),
              // Mini chart
              Container(
                height: 50,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: color,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: color.withOpacity(0.1),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(enabled: false),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SummaryItemWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const SummaryItemWidget({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
      ],
    );
  }
}

class ActivityItemWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final bool highlight;

  const ActivityItemWidget({
    Key? key,
    required this.icon,
    required this.title,
    required this.time,
    this.highlight = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: highlight ? Color(0xFFD2F8D1) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? Color(0xFF14AE5C) : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: highlight ? Color(0xFFA8E8B6) : Color(0xFFA8E8B6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: highlight ? Color(0xFF14AE5C) : Color(0xFF14AE5C),
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScanFABWidget extends StatelessWidget {
  final VoidCallback onTap;
  final Animation<double> breathingAnimation;

  const ScanFABWidget({
    Key? key,
    required this.onTap,
    required this.breathingAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: breathingAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: breathingAnimation.value * 0.05 + 0.95,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF4CAF50),
                    Color(0xFF2E7D32),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4CAF50)
                        .withOpacity(0.3 * breathingAnimation.value),
                    blurRadius: 12 * breathingAnimation.value,
                    offset: Offset(0, 5),
                    spreadRadius: 2 * (breathingAnimation.value - 0.92) * 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        );
      },
    );
  }
}

class SideMenuWidget extends StatelessWidget {
  final String name;
  final String role;
  final String? photoProfile;
  final List<Map<String, dynamic>> menuItems;
  final Animation<double> menuAnimation;
  final VoidCallback onClose;
  final AuthenticationController authController =
      Get.find<AuthenticationController>();

  SideMenuWidget({
    Key? key,
    required this.name,
    required this.role,
    this.photoProfile,
    required this.menuItems,
    required this.menuAnimation,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: menuAnimation,
      builder: (context, child) {
        return menuAnimation.value > 0
            ? GestureDetector(
                onTap: onClose,
                child: Container(
                  color: Colors.black.withOpacity(0.4 * menuAnimation.value),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(-1, 0),
                        end: Offset(0, 0),
                      ).animate(menuAnimation),
                      child: _buildMenuContent(context),
                    ),
                  ),
                ),
              )
            : SizedBox.shrink();
      },
    );
  }

  Widget _buildMenuContent(BuildContext context) {
    // Use Obx to listen to changes in currentUser from the AuthenticationController
    return Obx(() {
      // This will rebuild whenever the AuthenticationController's currentUser changes
      final currentUser = authController.currentUser.value;
      final userName = currentUser?.name ?? name;
      final userRole = currentUser?.role == UserRole.adminPenyemaian
          ? "Admin Penyemaian"
          : "Admin TPK";
      final userPhoto = currentUser?.photoUrl ?? photoProfile;

      return Container(
        width: MediaQuery.of(context).size.width * 0.75,
        height: MediaQuery.of(context).size.height,
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Profile section
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4CAF50).withOpacity(0.9),
                      Color(0xFF2E7D32),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    // Profile picture with real-time updates
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: userPhoto != null && userPhoto.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                userPhoto,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  );
                                },
                                // Add cache-busting parameter to force refresh of the image
                                // This ensures the image is reloaded after updates
                                cacheWidth: 160,
                                errorBuilder: (context, error, stackTrace) {
                                  print("Error loading profile image: $error");
                                  return Icon(
                                    Icons.person_rounded,
                                    size: 50,
                                    color: Color(0xFF4CAF50),
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: Color(0xFF4CAF50),
                            ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      userName, // Use the updated userName value
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        userRole, // Use the updated userRole value
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Menu items
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  physics: BouncingScrollPhysics(),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    return _buildMenuItem(
                      icon: item['icon'],
                      title: item['title'],
                      isActive: item['isActive'] ?? false,
                      isDestructive: item['isDestructive'] ?? false,
                      onTap: item['onTap'],
                    );
                  },
                ),
              ),

              // App version
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.eco_outlined,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                    SizedBox(width: 5),
                    Text(
                      "Green Track v1.0.0",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    final Color textColor = isDestructive
        ? Colors.red
        : (isActive ? Color(0xFF4CAF50) : Colors.grey[700]!);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            color: isActive
                ? Color(0xFF4CAF50).withOpacity(0.1)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isActive ? Color(0xFF4CAF50) : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: textColor,
              ),
              SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Function to confirm logout - common for both dashboards
void showLogoutConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Logout"),
      content: Text("Apakah Anda yakin ingin keluar?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Batal"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // Return to login screen
            Get.offAll(() => LoginScreen());
          },
          child: Text(
            "Logout",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}
