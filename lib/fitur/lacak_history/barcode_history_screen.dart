import 'package:flutter/material.dart';
import 'package:flutter_green_track/fitur/lacak_history/user_activity_model.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class BarcodeScanHistoryScreen extends StatefulWidget {
  const BarcodeScanHistoryScreen({Key? key}) : super(key: key);

  @override
  _BarcodeScanHistoryScreenState createState() =>
      _BarcodeScanHistoryScreenState();
}

class _BarcodeScanHistoryScreenState extends State<BarcodeScanHistoryScreen> {
  final appController = Get.find<AppController>();
  bool _isLoading = true;
  List<UserActivity> _scanActivities = [];

  @override
  void initState() {
    super.initState();
    _loadScanActivities();
  }

  Future<void> _loadScanActivities() async {
    setState(() {
      _isLoading = true;
    });

    // Tambahkan delay sedikit untuk animasi loading
    await Future.delayed(const Duration(milliseconds: 500));

    // Dapatkan aktivitas scan barcode dari controller
    _scanActivities = appController.getScanBarcodeActivities();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Riwayat Scan Barcode',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              appController.syncActivitiesFromFirestore(limit: 50).then((_) {
                _loadScanActivities();
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await appController.syncActivitiesFromFirestore(limit: 50);
          _loadScanActivities();
        },
        child: _isLoading
            ? _buildLoadingShimmer()
            : _scanActivities.isEmpty
                ? _buildEmptyState()
                : _buildActivityList(),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner_rounded,
            size: 100,
            color: Color(0xFF4CAF50).withOpacity(0.5),
          ),
          SizedBox(height: 20),
          Text(
            "Belum Ada Riwayat Scan",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Anda belum melakukan pemindaian barcode apapun",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _scanActivities.length,
      itemBuilder: (context, index) {
        final activity = _scanActivities[index];
        final scanDetails = activity.metadata ?? {};

        return Card(
          elevation: 1,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _showActivityDetails(activity),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Color(0xFF2E7D32),
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.description,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        if (scanDetails['bibitId'] != null ||
                            scanDetails['kayuId'] != null)
                          Text(
                            scanDetails['bibitId'] != null
                                ? 'ID Bibit: ${scanDetails['bibitId']}'
                                : 'ID Kayu: ${scanDetails['kayuId']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        SizedBox(height: 4),
                        Text(
                          _formatTimestamp(activity.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showActivityDetails(UserActivity activity) {
    final scanDetails = activity.metadata ?? {};
    final targetId = activity.targetId ?? 'Tidak ada';

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Color(0xFF2E7D32),
                  size: 40,
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                activity.description,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),
            _detailRow(
                'Waktu', _formatTimestamp(activity.timestamp, detailed: true)),
            Divider(height: 24),
            _detailRow('Tipe', 'Scan Barcode'),
            Divider(height: 24),
            _detailRow('Target ID', targetId),
            if (scanDetails.isNotEmpty) ...[
              Divider(height: 24),
              Text(
                'Detail Tambahan:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              ...scanDetails.entries.map((entry) {
                if (entry.key != 'userName' &&
                    entry.key != 'userEmail' &&
                    entry.key != 'userPhotoUrl') {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _detailRow(_formatKey(entry.key),
                        entry.value?.toString() ?? 'Tidak ada'),
                  );
                } else {
                  return SizedBox.shrink();
                }
              }).toList(),
            ],
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatKey(String key) {
    // Mengubah camelCase menjadi Title Case dengan spasi
    final result = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    return result.substring(0, 1).toUpperCase() + result.substring(1);
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label + ':',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to format timestamp
  String _formatTimestamp(DateTime timestamp, {bool detailed = false}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final dateToCheck =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (detailed) {
      return DateFormat('dd MMMM yyyy, HH:mm:ss').format(timestamp);
    }

    if (dateToCheck == today) {
      return 'Hari ini, ${DateFormat('HH:mm').format(timestamp)}';
    } else if (dateToCheck == yesterday) {
      return 'Kemarin, ${DateFormat('HH:mm').format(timestamp)}';
    } else {
      return DateFormat('dd MMM yyyy, HH:mm').format(timestamp);
    }
  }
}

// Extension untuk AppController
extension ScanBarcodeActivities on AppController {
  // Mendapatkan semua aktivitas scan barcode
  List<UserActivity> getScanBarcodeActivities() {
    return recentActivities
        .where((activity) => activity.activityType == ActivityTypes.scanBarcode)
        .toList();
  }
}
