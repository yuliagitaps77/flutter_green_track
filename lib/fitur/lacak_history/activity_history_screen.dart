import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';
import 'package:flutter_green_track/fitur/dashboard_penyemaian/admin_dashboard_penyemaian.dart';
import 'package:flutter_green_track/fitur/lacak_history/user_activity_model.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// ======= ADMIN PENYEMAIAN HISTORY PAGE =======
// ======= REDESIGNED PENYEMAIAN HISTORY PAGE =======
class PenyemaianHistoryPage extends StatefulWidget {
  const PenyemaianHistoryPage({Key? key}) : super(key: key);

  @override
  State<PenyemaianHistoryPage> createState() => _PenyemaianHistoryPageState();
}

class _PenyemaianHistoryPageState extends State<PenyemaianHistoryPage> {
  final AppController appController = Get.find<AppController>();
  final AuthenticationController authController =
      Get.find<AuthenticationController>();

  // Filter options
  final List<String> filterOptions = [
    'Semua Aktivitas',
    'Bibit',
    'Jadwal Perawatan',
    'Login/Logout',
  ];
  String selectedFilter = 'Semua Aktivitas';

  // For pagination
  final int itemsPerPage = 20;
  bool isLoading = false;
  bool hasMoreData = true;

  @override
  void initState() {
    super.initState();
    // Sync with Firestore to get up-to-date data
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      isLoading = true;
    });

    // Sync with Firestore to get latest activities
    await appController.syncActivitiesFromFirestore(limit: 50);

    setState(() {
      isLoading = false;
    });
  }

  List<UserActivity> _getFilteredActivities() {
    // Get current user
    final currentUser = authController.currentUser.value;
    if (currentUser == null) return [];

    // Get activities filtered by user ID to show only current user's activities
    List<UserActivity> activities = appController.recentActivities
        .where((activity) => activity.userId == currentUser.id)
        .toList();

    // Apply filter
    switch (selectedFilter) {
      case 'Bibit':
        return activities
            .where((activity) =>
                activity.activityType == ActivityTypes.scanBarcode ||
                activity.activityType == ActivityTypes.printBarcode ||
                activity.activityType == ActivityTypes.updateBibit ||
                activity.activityType == ActivityTypes.deleteBibit)
            .toList();

      case 'Jadwal Perawatan':
        return activities
            .where((activity) => activity.activityType.contains('JADWAL'))
            .toList();

      case 'Login/Logout':
        return activities
            .where((activity) =>
                activity.activityType == ActivityTypes.userLogin ||
                activity.activityType == ActivityTypes.userLogout ||
                activity.activityType == ActivityTypes.updateUserProfile ||
                activity.activityType == ActivityTypes.changePassword)
            .toList();

      case 'Semua Aktivitas':
      default:
        return activities;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Enhanced AppBar with gradient background
      appBar: AppBar(
        title: const Text(
          "Riwayat Aktivitas",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: _loadInitialData,
            tooltip: 'Refresh data',
          ),
        ],
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Apply a subtle background gradient
      backgroundColor: Color(0xFFF9FBFA),
      body: Column(
        children: [
          // Enhanced Filter section
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      color: Color(0xFF2E7D32),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Filter Aktivitas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: BouncingScrollPhysics(),
                  child: Row(
                    children: filterOptions
                        .map((filter) => Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: FilterChip(
                                label: Text(
                                  filter,
                                  style: TextStyle(
                                    color: selectedFilter == filter
                                        ? Colors.white
                                        : Color(0xFF4CAF50),
                                    fontWeight: selectedFilter == filter
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                selected: selectedFilter == filter,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      selectedFilter = filter;
                                    });
                                  }
                                },
                                backgroundColor: Colors.white,
                                selectedColor: Color(0xFF4CAF50),
                                checkmarkColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: Color(0xFFCCE8CF),
                                    width: 1.5,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                elevation: 0,
                                pressElevation: 2,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // Activity list with enhanced styling
          Expanded(
            child: Obx(() {
              final activities = _getFilteredActivities();

              if (isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                  ),
                );
              }

              if (activities.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.history,
                          size: 60,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Belum ada aktivitas',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF757575),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Aktivitas Anda akan muncul di sini',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: RefreshIndicator(
                  onRefresh: _loadInitialData,
                  color: Color(0xFF4CAF50),
                  child: ListView.builder(
                    itemCount: activities.length,
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return ActivityListItem(
                        activity: activity,
                        isFirst: index == 0,
                        isLast: index == activities.length - 1,
                        color: Color(0xFF4CAF50),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ======= REDESIGNED TPK HISTORY PAGE =======
class TPKHistoryPage extends StatefulWidget {
  const TPKHistoryPage({Key? key}) : super(key: key);

  @override
  State<TPKHistoryPage> createState() => _TPKHistoryPageState();
}

class _TPKHistoryPageState extends State<TPKHistoryPage> {
  final AppController appController = Get.find<AppController>();
  final AuthenticationController authController =
      Get.find<AuthenticationController>();

  // Filter options
  final List<String> filterOptions = [
    'Semua Aktivitas',
    'Kayu',
    'Login/Logout',
  ];
  String selectedFilter = 'Semua Aktivitas';

  // For pagination
  final int itemsPerPage = 20;
  bool isLoading = false;
  bool hasMoreData = true;

  @override
  void initState() {
    super.initState();
    // Sync with Firestore to get up-to-date data
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      isLoading = true;
    });

    // Sync with Firestore to get latest activities
    await appController.syncActivitiesFromFirestore(limit: 50);

    setState(() {
      isLoading = false;
    });
  }

  List<UserActivity> _getFilteredActivities() {
    // Get current user
    final currentUser = authController.currentUser.value;
    if (currentUser == null) return [];

    // Get activities filtered by user ID to show only current user's activities
    List<UserActivity> activities = appController.recentActivities
        .where((activity) => activity.userId == currentUser.id)
        .toList();

    // Apply filter
    switch (selectedFilter) {
      case 'Kayu':
        return activities
            .where((activity) =>
                activity.activityType == ActivityTypes.addKayu ||
                activity.activityType == ActivityTypes.updateKayu ||
                activity.activityType == ActivityTypes.deleteKayu ||
                activity.activityType == ActivityTypes.scanPohon)
            .toList();

      case 'Pengiriman':
        return activities
            .where((activity) =>
                activity.activityType == ActivityTypes.addPengiriman)
            .toList();

      case 'Login/Logout':
        return activities
            .where((activity) =>
                activity.activityType == ActivityTypes.userLogin ||
                activity.activityType == ActivityTypes.userLogout ||
                activity.activityType == ActivityTypes.updateUserProfile ||
                activity.activityType == ActivityTypes.changePassword)
            .toList();

      case 'Semua Aktivitas':
      default:
        return activities;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Enhanced AppBar with gradient background (same style as Penyemaian)
      appBar: AppBar(
        title: const Text(
          "Riwayat Aktivitas TPK",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: _loadInitialData,
            tooltip: 'Refresh data',
          ),
        ],
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Apply a subtle background gradient (same as Penyemaian)
      backgroundColor: Color(0xFFF9FBFA),
      body: Column(
        children: [
          // Enhanced Filter section (same style as Penyemaian)
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      color: Color(0xFF2E7D32),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Filter Aktivitas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: BouncingScrollPhysics(),
                  child: Row(
                    children: filterOptions
                        .map((filter) => Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: FilterChip(
                                label: Text(
                                  filter,
                                  style: TextStyle(
                                    color: selectedFilter == filter
                                        ? Colors.white
                                        : Color(0xFF4CAF50),
                                    fontWeight: selectedFilter == filter
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                selected: selectedFilter == filter,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      selectedFilter = filter;
                                    });
                                  }
                                },
                                backgroundColor: Colors.white,
                                selectedColor: Color(0xFF4CAF50),
                                checkmarkColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: Color(0xFFCCE8CF),
                                    width: 1.5,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                elevation: 0,
                                pressElevation: 2,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // Activity list with enhanced styling (same as Penyemaian)
          Expanded(
            child: Obx(() {
              final activities = _getFilteredActivities();

              if (isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                  ),
                );
              }

              if (activities.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.history,
                          size: 60,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Belum ada aktivitas',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF757575),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Aktivitas Anda akan muncul di sini',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: RefreshIndicator(
                  onRefresh: _loadInitialData,
                  color: Color(0xFF4CAF50),
                  child: ListView.builder(
                    itemCount: activities.length,
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return ActivityListItem(
                        activity: activity,
                        isFirst: index == 0,
                        isLast: index == activities.length - 1,
                        color: Color(0xFF4CAF50),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ======= ENHANCED SHARED COMPONENTS =======

// Enhanced Activity list item with timeline style
class ActivityListItem extends StatelessWidget {
  final UserActivity activity;
  final bool isFirst;
  final bool isLast;
  final Color color;

  const ActivityListItem({
    Key? key,
    required this.activity,
    this.isFirst = false,
    this.isLast = false,
    this.color = const Color(0xFF4CAF50), // Default to green for both pages
  }) : super(key: key);

  // Helper method to get icon data (unchanged)
  IconData _getIconData(String? iconString) {
    if (iconString == null) return Icons.history;

    switch (iconString) {
      case 'Icons.login_rounded':
        return Icons.login_rounded;
      case 'Icons.logout_rounded':
        return Icons.logout_rounded;
      case 'Icons.person_rounded':
        return Icons.person_rounded;
      case 'Icons.password_rounded':
        return Icons.password_rounded;
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
      case 'Icons.local_shipping_rounded':
        return Icons.local_shipping_rounded;
      case 'Icons.add_circle_outline_rounded':
        return Icons.add_circle_outline_rounded;
      default:
        return Icons.history;
    }
  }

  // Format timestamp (unchanged)
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
      return DateFormat('dd MMM yyyy, HH:mm').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Enhanced Timeline element
            Container(
              width: 50,
              child: Column(
                children: [
                  // Top line
                  if (!isFirst)
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: 2,
                        color: Color(0xFFE0E0E0),
                      ),
                    ),

                  // Circle icon with animation
                  TweenAnimationBuilder(
                    duration: Duration(milliseconds: 500),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.2),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            _getIconData(activity.icon),
                            color: color,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),

                  // Bottom line
                  if (!isLast)
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: 2,
                        color: Color(0xFFE0E0E0),
                      ),
                    ),
                ],
              ),
            ),

            // Enhanced Activity content
            Expanded(
              child: TweenAnimationBuilder(
                duration: Duration(milliseconds: 500),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(20 * (1 - value), 0),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Activity description
                      Text(
                        activity.description,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF424242),
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 10),

                      // Activity time with enhanced style
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFF5F9F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: color.withOpacity(0.7),
                            ),
                            SizedBox(width: 4),
                            Text(
                              _formatTimestamp(activity.timestamp),
                              style: TextStyle(
                                color: Color(0xFF757575),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Show metadata if available with enhanced styling
                      if (activity.metadata != null &&
                          activity.metadata!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFFEEEEEE),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Detail Aktivitas',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Color(0xFF616161),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Divider(height: 1, thickness: 1),
                                SizedBox(height: 6),
                                ...activity.metadata!.entries.map((entry) {
                                  // Skip userName and userEmail in metadata as they're duplicates
                                  if (entry.key == 'userName' ||
                                      entry.key == 'userEmail' ||
                                      entry.key == 'userPhotoUrl') {
                                    return SizedBox.shrink();
                                  }

                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_formatMetadataKey(entry.key)}: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            color: Color(0xFF616161),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${entry.value}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF757575),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to format metadata keys for better readability
  String _formatMetadataKey(String key) {
    // Replace camelCase with spaces and capitalize
    final formattedKey = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    // Capitalize first letter
    return formattedKey.substring(0, 1).toUpperCase() +
        formattedKey.substring(1);
  }
}

// For integration in main navigation (unchanged functionality)
class HistoryNavigator {
  // Navigate to appropriate history page based on user role
  static void goToHistoryPage(BuildContext context) {
    final authController = Get.find<AuthenticationController>();
    final userRole = authController.currentUser.value?.role;

    if (userRole == UserRole.adminPenyemaian) {
      Get.to(() => PenyemaianHistoryPage());
    } else if (userRole == UserRole.adminTPK) {
      Get.to(() => TPKHistoryPage());
    } else {
      // Default fallback
      Get.snackbar(
        'Informasi',
        'Riwayat aktivitas tidak tersedia untuk peran ini',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFF4CAF50).withOpacity(0.1),
        colorText: Color(0xFF4CAF50),
        duration: Duration(seconds: 3),
      );
    }
  }
}
