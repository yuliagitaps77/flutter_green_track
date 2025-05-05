import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';
import 'package:flutter_green_track/fitur/dashboard_penyemaian/admin_dashboard_penyemaian.dart';
import 'package:flutter_green_track/fitur/lacak_history/user_activity_model.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({Key? key}) : super(key: key);

  @override
  _ActivityHistoryScreenState createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  final appController = Get.find<AppController>();
  final authController = Get.find<AuthenticationController>();
  bool _isLoading = true;
  List<UserActivity> _allActivities = [];
  Map<String, List<UserActivity>> _groupedActivities = {};
  String _selectedFilter = 'Semua';

  // Date filter
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isDateFilterActive = false;

  // Filter options - akan diisi secara dinamis berdasarkan role pengguna
  late List<String> _filterOptions;

  // Activity type mapping untuk filter
  final Map<String, String> _activityTypeMap = {
    'Scan Barcode': ActivityTypes.scanBarcode,
    'Print Barcode': ActivityTypes.printBarcode,
    'Update Bibit': ActivityTypes.updateBibit,
    'Delete Bibit': ActivityTypes.deleteBibit,
    'Jadwal Rawat': ActivityTypes.addJadwalRawat,
    'Update Kayu': ActivityTypes.updateKayu,
    'Delete Kayu': ActivityTypes.deleteKayu,
    'Pengiriman': ActivityTypes.addPengiriman,
  };

  @override
  void initState() {
    super.initState();
    _initFilterOptions();
    _loadActivities();
  }

  // Inisialisasi filter options berdasarkan role user
  void _initFilterOptions() {
    final userRole = authController.currentUser.value?.role.toString() ?? '';

    // Default options untuk semua pengguna
    final baseOptions = ['Semua'];

    // Opsi tambahan berdasarkan role
    if (userRole.contains('ADMIN_PENYEMAIAN')) {
      // Sesuai dengan extension DashboardIntegration.getPenyemaianActivities
      baseOptions.addAll([
        'Scan Barcode',
        'Print Barcode',
        'Update Bibit',
        'Delete Bibit',
        'Jadwal Rawat'
      ]);
    } else if (userRole.contains('ADMIN_TPK')) {
      // Sesuai dengan extension DashboardIntegration.getTPKActivities
      baseOptions
          .addAll(['Scan Barcode', 'Update Kayu', 'Delete Kayu', 'Pengiriman']);
    } else {
      // Jika tidak diketahui atau superadmin, tambahkan semua opsi
      baseOptions.addAll([
        'Scan Barcode',
        'Print Barcode',
        'Update Bibit',
        'Delete Bibit',
        'Jadwal Rawat',
        'Update Kayu',
        'Delete Kayu',
        'Pengiriman'
      ]);
    }

    _filterOptions = baseOptions;
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    // Ambil data dari controller berdasarkan role
    final userRole = authController.currentUser.value?.role.toString() ?? '';

    if (userRole.contains('ADMIN_PENYEMAIAN')) {
      // Untuk admin penyemaian, gunakan filter aktivitas penyemaian
      if (_selectedFilter == 'Semua') {
        _allActivities = appController.getPenyemaianActivities(limit: 1000);
      } else {
        // Filter berdasarkan pilihan tipe aktivitas
        final activityType = _activityTypeMap[_selectedFilter];
        if (activityType != null) {
          _allActivities = appController.recentActivities
              .where((activity) => activity.activityType == activityType)
              .toList();
        }
      }
    } else if (userRole.contains('ADMIN_TPK')) {
      // Untuk admin TPK, gunakan filter aktivitas TPK
      if (_selectedFilter == 'Semua') {
        _allActivities = appController.getTPKActivities(limit: 1000);
      } else {
        // Filter berdasarkan pilihan tipe aktivitas
        final activityType = _activityTypeMap[_selectedFilter];
        if (activityType != null) {
          _allActivities = appController.recentActivities
              .where((activity) => activity.activityType == activityType)
              .toList();
        }
      }
    } else {
      // Untuk superadmin atau role lain, tampilkan semua aktivitas
      _allActivities = List.from(appController.recentActivities);

      // Filter berdasarkan pilihan filter
      if (_selectedFilter != 'Semua') {
        final activityType = _activityTypeMap[_selectedFilter];
        if (activityType != null) {
          _allActivities = _allActivities
              .where((activity) => activity.activityType == activityType)
              .toList();
        }
      }
    }

    // Filter berdasarkan tanggal jika filter tanggal aktif
    if (_isDateFilterActive && _startDate != null && _endDate != null) {
      // Tambahkan 1 hari ke endDate agar termasuk hari tersebut sepenuhnya
      final adjustedEndDate = _endDate!.add(Duration(days: 1));

      _allActivities = _allActivities.where((activity) {
        return activity.timestamp.isAfter(_startDate!) &&
            activity.timestamp.isBefore(adjustedEndDate);
      }).toList();
    }

    // Kelompokkan berdasarkan tanggal untuk tampilan lebih terorganisir
    _groupActivitiesByDate();

    setState(() {
      _isLoading = false;
    });
  }

  void _groupActivitiesByDate() {
    _groupedActivities = {};

    for (var activity in _allActivities) {
      final date = DateFormat('yyyy-MM-dd').format(activity.timestamp);
      if (!_groupedActivities.containsKey(date)) {
        _groupedActivities[date] = [];
      }
      _groupedActivities[date]!.add(activity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _buildFilterChips(),
          _buildDateFilter(),
          SliverToBoxAdapter(
            child: Divider(
              height: 32,
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),
          ),
          _isLoading
              ? SliverFillRemaining(child: _buildLoadingIndicator())
              : _groupedActivities.isEmpty
                  ? SliverFillRemaining(child: _buildEmptyState())
                  : _buildActivityGroupList(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final userRole = authController.currentUser.value?.role.toString() ?? '';
    final bool isAdminPenyemaian = userRole.contains('ADMIN_PENYEMAIAN');
    final bool isAdminTPK = userRole.contains('ADMIN_TPK');

    // Menentukan warna berdasarkan role
    final Color primaryColor = isAdminTPK
        ? Color(0xFF1565C0) // Biru untuk TPK
        : Color(0xFF2E7D32); // Hijau untuk Penyemaian

    final Color secondaryColor =
        isAdminTPK ? Color(0xFF1976D2) : Color(0xFF388E3C);

    // Avatar text berdasarkan role
    final String avatarText = isAdminTPK
        ? 'TPK'
        : isAdminPenyemaian
            ? 'PN'
            : 'AD';

    // Judul berdasarkan role
    final String title = isAdminTPK
        ? 'Riwayat Aktivitas TPK'
        : isAdminPenyemaian
            ? 'Riwayat Aktivitas Penyemaian'
            : 'Riwayat Semua Aktivitas';

    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      stretch: true,
      backgroundColor: primaryColor,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: () {
            appController.syncActivitiesFromFirestore(limit: 100).then((_) {
              _loadActivities();
            });
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                secondaryColor,
                primaryColor,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -15,
                top: -15,
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -10,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),
              // Avatar pengguna di header
              Positioned(
                right: 20,
                bottom: 60,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      avatarText,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    // Mendapatkan warna berdasarkan role untuk konsistensi
    final userRole = authController.currentUser.value?.role.toString() ?? '';
    final bool isAdminTPK = userRole.contains('ADMIN_TPK');

    final Color accentColor = isAdminTPK
        ? Color(0xFF1565C0) // TPK
        : Color(0xFF2E7D32); // Penyemaian

    final Color lightAccentColor = isAdminTPK
        ? Color(0xFFE3F2FD) // Light blue untuk TPK
        : Color(0xFFE8F5E9); // Light green untuk Penyemaian

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              "Filter Tipe Aktivitas",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
          Container(
            height: 50,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final option = _filterOptions[index];
                final isSelected = _selectedFilter == option;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = option;
                      });
                      _loadActivities();
                    },
                    selectedColor: lightAccentColor,
                    checkmarkColor: accentColor,
                    labelStyle: TextStyle(
                      color: isSelected ? accentColor : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? accentColor : Colors.transparent,
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk filter tanggal
  Widget _buildDateFilter() {
    // Mendapatkan warna berdasarkan role untuk konsistensi
    final userRole = authController.currentUser.value?.role.toString() ?? '';
    final bool isAdminTPK = userRole.contains('ADMIN_TPK');

    final Color accentColor = isAdminTPK
        ? Color(0xFF1565C0) // TPK
        : Color(0xFF2E7D32); // Penyemaian

    final Color lightAccentColor = isAdminTPK
        ? Color(0xFFE3F2FD) // Light blue untuk TPK
        : Color(0xFFE8F5E9); // Light green untuk Penyemaian

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Filter Tanggal",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                if (_isDateFilterActive)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDateFilterActive = false;
                        _startDate = null;
                        _endDate = null;
                      });
                      _loadActivities();
                    },
                    child: Text(
                      "Reset",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.red[400],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _isDateFilterActive
                ? _buildActiveDateFilter(accentColor, lightAccentColor)
                : _buildDateFilterButton(accentColor, lightAccentColor),
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan filter tanggal yang aktif
  Widget _buildActiveDateFilter(Color accentColor, Color lightAccentColor) {
    // Format untuk menampilkan range tanggal
    final DateFormat formatter = DateFormat('dd MMM yyyy');
    final String startDateStr =
        _startDate != null ? formatter.format(_startDate!) : '';
    final String endDateStr =
        _endDate != null ? formatter.format(_endDate!) : '';

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: lightAccentColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range,
            color: accentColor,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "$startDateStr - $endDateStr",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: accentColor,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              color: accentColor,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            onPressed: () => _showDateRangePicker(accentColor),
          ),
        ],
      ),
    );
  }

  // Widget untuk tombol pilih tanggal
  Widget _buildDateFilterButton(Color accentColor, Color lightAccentColor) {
    return ElevatedButton.icon(
      onPressed: () => _showDateRangePicker(accentColor),
      icon: Icon(
        Icons.date_range,
        size: 20,
      ),
      label: Text("Pilih Rentang Tanggal"),
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Tampilkan dialog pemilihan rentang tanggal
  void _showDateRangePicker(Color accentColor) async {
    final initialDateRange = _startDate != null && _endDate != null
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : DateTimeRange(
            start: DateTime.now().subtract(Duration(days: 7)),
            end: DateTime.now(),
          );

    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: accentColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: accentColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDateRange != null) {
      setState(() {
        _startDate = pickedDateRange.start;
        _endDate = pickedDateRange.end;
        _isDateFilterActive = true;
      });
      _loadActivities();
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat aktivitas...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    // Ambil warna berdasarkan role
    final userRole = authController.currentUser.value?.role.toString() ?? '';
    final bool isAdminTPK = userRole.contains('ADMIN_TPK');

    final Color accentColor =
        isAdminTPK ? Color(0xFF1976D2) : Color(0xFF4CAF50);
    final Color textColor = isAdminTPK ? Color(0xFF1565C0) : Color(0xFF2E7D32);
    final Color lightBgColor =
        isAdminTPK ? Color(0xFFE3F2FD) : Color(0xFFE8F5E9);

    String emptyMessage;
    if (_isDateFilterActive) {
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      final String dateRange =
          "${formatter.format(_startDate!)} - ${formatter.format(_endDate!)}";

      if (_selectedFilter == 'Semua') {
        emptyMessage = "Tidak ada aktivitas dalam rentang tanggal $dateRange";
      } else {
        emptyMessage =
            "Tidak ada aktivitas $_selectedFilter dalam rentang tanggal $dateRange";
      }
    } else {
      if (_selectedFilter == 'Semua') {
        emptyMessage = "Belum ada aktivitas yang tercatat dalam sistem";
      } else {
        emptyMessage = "Belum ada aktivitas $_selectedFilter yang tercatat";
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: lightBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isDateFilterActive ? Icons.date_range : Icons.history_rounded,
              size: 50,
              color: accentColor,
            ),
          ),
          SizedBox(height: 24),
          Text(
            "Tidak Ada Aktivitas",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          // Tambahkan tombol reset jika ada filter aktif
          if (_isDateFilterActive || _selectedFilter != 'Semua')
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isDateFilterActive = false;
                    _startDate = null;
                    _endDate = null;
                    _selectedFilter = 'Semua';
                  });
                  _loadActivities();
                },
                icon: Icon(Icons.refresh_outlined),
                label: Text('Reset Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityGroupList() {
    // Sort dates in descending order (newest first)
    final sortedDates = _groupedActivities.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final date = sortedDates[index];
          final activities = _groupedActivities[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _buildDateHeader(date),
              ),
              ...activities
                  .map((activity) => _buildActivityItem(activity))
                  .toList(),
              SizedBox(height: index == sortedDates.length - 1 ? 16 : 0),
            ],
          );
        },
        childCount: sortedDates.length,
      ),
    );
  }

  Widget _buildDateHeader(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    String formattedDate;
    if (dateToCheck == today) {
      formattedDate = 'Hari Ini';
    } else if (dateToCheck == yesterday) {
      formattedDate = 'Kemarin';
    } else {
      formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(0xFF388E3C),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            formattedDate,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            indent: 8,
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(UserActivity activity) {
    final iconData = _getIconData(activity.icon);
    final iconColor = _getColorForActivityType(activity.activityType);
    final backgroundColor = iconColor.withOpacity(0.1);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        onTap: () => _showActivityDetails(activity),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              activity.description,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(activity.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        _getActivityTypeName(activity.activityType),
                        style: TextStyle(
                          fontSize: 14,
                          color: iconColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (activity.targetId != null) ...[
                        SizedBox(height: 4),
                        Text(
                          'Target ID: ${activity.targetId}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (activity.metadata != null &&
                          activity.metadata!.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Row(
                          children: [
                            _buildMetadataChip(activity),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataChip(UserActivity activity) {
    // Menampilkan indikator bahwa ada detail tambahan
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Detail Lainnya',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  void _showActivityDetails(UserActivity activity) {
    final metadata = activity.metadata ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                controller: scrollController,
                children: [
                  SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: _getColorForActivityType(activity.activityType)
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconData(activity.icon),
                        color: _getColorForActivityType(activity.activityType),
                        size: 40,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      activity.description,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getColorForActivityType(activity.activityType)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getColorForActivityType(activity.activityType)
                              .withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getActivityTypeName(activity.activityType),
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              _getColorForActivityType(activity.activityType),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  _buildDetailItem(
                    Icons.access_time_rounded,
                    'Waktu',
                    DateFormat('dd MMMM yyyy, HH:mm:ss')
                        .format(activity.timestamp),
                  ),
                  Divider(height: 24),
                  _buildDetailItem(
                    Icons.person_outline,
                    'User ID',
                    activity.userId,
                  ),
                  Divider(height: 24),
                  _buildDetailItem(
                    Icons.badge_outlined,
                    'User Role',
                    _formatUserRole(activity.userRole),
                  ),
                  if (activity.targetId != null) ...[
                    Divider(height: 24),
                    _buildDetailItem(
                      Icons.hub_outlined,
                      'Target ID',
                      activity.targetId!,
                    ),
                  ],
                  if (metadata.isNotEmpty) ...[
                    Divider(height: 32),
                    Text(
                      'Detail Tambahan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),
                    ...metadata.entries.map((entry) {
                      if (entry.key != 'userName' &&
                          entry.key != 'userEmail' &&
                          entry.key != 'userPhotoUrl') {
                        return Column(
                          children: [
                            _buildDetailItem(
                              Icons.info_outline,
                              _formatKey(entry.key),
                              entry.value?.toString() ?? 'Tidak ada',
                            ),
                            Divider(height: 24),
                          ],
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    }).toList(),
                  ],
                  SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.grey[700],
            size: 20,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper function untuk konversi string icon ke IconData
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

  // Helper function mendapatkan nama user-friendly untuk activity type
  String _getActivityTypeName(String activityType) {
    switch (activityType) {
      case ActivityTypes.scanBarcode:
        return 'Scan Barcode';
      case ActivityTypes.printBarcode:
        return 'Print Barcode';
      case ActivityTypes.updateBibit:
        return 'Update Bibit';
      case ActivityTypes.deleteBibit:
        return 'Delete Bibit';
      case ActivityTypes.addJadwalRawat:
        return 'Tambah Jadwal Rawat';
      case ActivityTypes.updateKayu:
        return 'Update Kayu';
      case ActivityTypes.deleteKayu:
        return 'Delete Kayu';
      case ActivityTypes.addPengiriman:
        return 'Tambah Pengiriman';
      default:
        return 'Aktivitas Lainnya';
    }
  }

  // Helper function mendapatkan warna berdasarkan activity type & role
  Color _getColorForActivityType(String activityType) {
    final userRole = authController.currentUser.value?.role.toString() ?? '';
    final bool isAdminTPK = userRole.contains('ADMIN_TPK');

    // Palette warna utama sesuai role
    final Color primaryGreen = Color(0xFF2E7D32);
    final Color primaryBlue = Color(0xFF1565C0);

    // Warna dasar berdasarkan role
    final Color baseColor = isAdminTPK ? primaryBlue : primaryGreen;

    switch (activityType) {
      case ActivityTypes.scanBarcode:
        return baseColor; // Primary color berdasarkan role
      case ActivityTypes.printBarcode:
        return isAdminTPK
            ? Color(0xFF1976D2)
            : Color(0xFF388E3C); // Shade primary color
      case ActivityTypes.updateBibit:
      case ActivityTypes.updateKayu:
        return Color(0xFFFF9800); // Orange tetap sama untuk intuisi
      case ActivityTypes.deleteBibit:
      case ActivityTypes.deleteKayu:
        return Color(0xFFE53935); // Red tetap sama untuk intuisi
      case ActivityTypes.addJadwalRawat:
        return isAdminTPK
            ? Color(0xFF7986CB)
            : Color(0xFF9C27B0); // Indigo/Purple
      case ActivityTypes.addPengiriman:
        return isAdminTPK
            ? Color(0xFF5D4037)
            : Color(0xFF795548); // Dark/Light Brown
      default:
        return Color(0xFF607D8B); // Blue Grey
    }
  }

  // Format user role to readable text
  String _formatUserRole(String role) {
    // Asumsi format role: 'UserRole.ADMIN_PENYEMAIAN'
    if (role.contains('.')) {
      final parts = role.split('.');
      if (parts.length > 1) {
        // Convert ADMIN_PENYEMAIAN to Admin Penyemaian
        return parts[1]
            .split('_')
            .map((word) =>
                word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
      }
    }
    return role;
  }

  // Format camelCase to Title Case
  String _formatKey(String key) {
    final result = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );

    return result.substring(0, 1).toUpperCase() + result.substring(1);
  }
}
