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
      appBar: AppBar(
        title: Text(
          'Riwayat Aktivitas Admin Penyemaian',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: EdgeInsets.all(16),
            color: Color(0xFFE8F5E9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Aktivitas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filterOptions
                        .map((filter) => Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(filter),
                                selected: selectedFilter == filter,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      selectedFilter = filter;
                                    });
                                  }
                                },
                                backgroundColor: Colors.white,
                                selectedColor: Color(0xFFA5D6A7),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // Activity list
          Expanded(
            child: Obx(() {
              final activities = _getFilteredActivities();

              if (isLoading) {
                return Center(child: CircularProgressIndicator());
              }

              if (activities.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada aktivitas',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _loadInitialData,
                child: ListView.builder(
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return ActivityListItem(
                      activity: activity,
                      isFirst: index == 0,
                      isLast: index == activities.length - 1,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ======= ADMIN TPK HISTORY PAGE =======
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
    'Pengiriman',
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
      appBar: AppBar(
        title: Text(
          'Riwayat Aktivitas Admin TPK',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF2E7D32), // Sama dengan Penyemaian (hijau)
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: EdgeInsets.all(16),
            color: Color(
                0xFFE8F5E9), // Light green untuk TPK sama dengan Penyemaian
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Aktivitas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filterOptions
                        .map((filter) => Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(filter),
                                selected: selectedFilter == filter,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      selectedFilter = filter;
                                    });
                                  }
                                },
                                backgroundColor: Colors.white,
                                selectedColor: Color(
                                    0xFFA5D6A7), // Green chip sama dengan Penyemaian
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // Activity list
          Expanded(
            child: Obx(() {
              final activities = _getFilteredActivities();

              if (isLoading) {
                return Center(child: CircularProgressIndicator());
              }

              if (activities.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada aktivitas',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _loadInitialData,
                child: ListView.builder(
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return ActivityListItem(
                      activity: activity,
                      isFirst: index == 0,
                      isLast: index == activities.length - 1,
                      color: Color(
                          0xFF2E7D32), // Hijau untuk TPK sama dengan Penyemaian
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
// ======= SHARED COMPONENTS =======

// Activity list item with timeline style
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
    this.color = const Color(0xFF2E7D32), // Default to green for Penyemaian
  }) : super(key: key);

  // Helper method to get icon data
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

  // Format timestamp
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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline element
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
                      color: Colors.grey.shade300,
                    ),
                  ),

                // Circle icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _getIconData(activity.icon),
                    color: color,
                    size: 20,
                  ),
                ),

                // Bottom line
                if (!isLast)
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),

          // Activity content
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
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
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Activity time and metadata
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _formatTimestamp(activity.timestamp),
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  // Show metadata if available
                  if (activity.metadata != null &&
                      activity.metadata!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: activity.metadata!.entries.map((entry) {
                            // Skip userName and userEmail in metadata as they're duplicates
                            if (entry.key == 'userName' ||
                                entry.key == 'userEmail' ||
                                entry.key == 'userPhotoUrl') {
                              return SizedBox.shrink();
                            }

                            return Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${entry.key}: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${entry.value}',
                                      style: TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// For integration in main navigation
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
      );
    }
  }
}
