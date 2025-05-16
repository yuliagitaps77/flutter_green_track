import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';
import 'package:intl/intl.dart';

class StatisticsDetailPage extends StatefulWidget {
  static String routeName = "/statistics-detail";

  @override
  _StatisticsDetailPageState createState() => _StatisticsDetailPageState();
}

class _StatisticsDetailPageState extends State<StatisticsDetailPage>
    with SingleTickerProviderStateMixin {
  final PenyemaianDashboardController controller =
      Get.find<PenyemaianDashboardController>();
  late TabController _tabController;
  String selectedPeriod = '6 Bulan';
  final List<String> periods = ['1 Bulan', '3 Bulan', '6 Bulan', '1 Tahun'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Refresh data when page opens
    controller.refreshDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? initialTab = Get.arguments as String?;
    if (initialTab != null) {
      _tabController.index = initialTab == 'incoming' ? 0 : 1;
    }

    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_rounded,
                          color: Color(0xFF2E7D32)),
                      onPressed: () => Get.back(),
                    ),
                    Text(
                      'Detail Statistik',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Spacer(),
                    // Period Selector
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPeriod,
                          icon: Icon(Icons.keyboard_arrow_down,
                              color: Color(0xFF4CAF50)),
                          items: periods.map((String period) {
                            return DropdownMenuItem<String>(
                              value: period,
                              child: Text(
                                period,
                                style: TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedPeriod = newValue;
                                // Refresh data when period changes
                                controller.refreshDashboardData();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Color(0xFF4CAF50),
                  ),
                  labelColor: Colors.white,
                  dividerColor: Colors.transparent,
                  unselectedLabelColor: Color(0xFF4CAF50),
                  tabs: [
                    Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                        child: Tab(text: 'Bibit Masuk')),
                    Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                        child: Tab(text: 'Pemindaian')),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIncomingPlantsTab(),
                    _buildScanningTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingPlantsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Incoming Plants Rate Card
          _buildStatCard(
            "Total Bibit Masuk",
            controller.totalBibitMasuk.value,
            "bibit",
            Icons.add_circle_outline_rounded,
            Color(0xFF4CAF50),
            controller.bibitMasukSpots,
          ),
          SizedBox(height: 20),
          // Additional Statistics
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.5,
            children: [
              _buildStatTile(
                "Total Bibit",
                controller.totalBibit.value,
                Icons.forest_rounded,
                Color(0xFF4CAF50),
              ),
              _buildStatTile(
                "Bibit Siap Tanam",
                controller.bibitSiapTanam.value,
                Icons.nature_people_rounded,
                Color(0xFF66BB6A),
              ),
              _buildStatTile(
                "Bibit Rusak",
                controller.bibitButuhPerhatian.value,
                Icons.warning_rounded,
                Color(0xFFFF9800),
              ),
              _buildStatTile(
                "Bibit Dipindai",
                controller.bibitDipindai.value,
                Icons.qr_code_scanner_rounded,
                Color(0xFF2E7D32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanningTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Scanning Rate Card
          _buildStatCard(
            "Total Pemindaian",
            controller.bibitDipindai.value,
            "bibit",
            Icons.qr_code_scanner_rounded,
            Color(0xFF66BB6A),
            controller.scannedSpots,
          ),
          SizedBox(height: 20),
          // Scanning History
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Riwayat Pemindaian",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                SizedBox(height: 15),
                Obx(() {
                  final scanHistory = controller.getScanHistory(selectedPeriod);
                  if (scanHistory.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Belum ada riwayat pemindaian",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: scanHistory.length,
                    itemBuilder: (context, index) {
                      final activity = scanHistory[index];
                      return _buildScanHistoryItem(
                        activity.description,
                        "ID: ${activity.id}",
                        _getTimeAgo(activity.timestamp),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return "${difference.inDays} hari yang lalu";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} jam yang lalu";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} menit yang lalu";
    } else {
      return "Baru saja";
    }
  }

  String getFormattedDate(DateTime date, String period) {
    if (period == '1 Bulan') {
      return DateFormat('dd/MM').format(date);
    } else if (period == '3 Bulan') {
      return 'M${date.difference(date.subtract(Duration(days: date.weekday - 1))).inDays ~/ 7 + 1}\n${DateFormat('MM').format(date)}';
    } else if (period == '6 Bulan') {
      return '${DateFormat('MM/yy').format(date)}';
    } else {
      return DateFormat('MM/yy').format(date);
    }
  }

  double getDateInterval(String period) {
    switch (period) {
      case '1 Bulan':
        return 1; // Show every day
      case '3 Bulan':
        return 7; // Show weekly
      case '6 Bulan':
        return 14; // Show bi-weekly
      case '1 Tahun':
        return 30; // Show monthly
      default:
        return 1;
    }
  }

  int getDataPoints(String period) {
    switch (period) {
      case '1 Bulan':
        return 30; // 30 days
      case '3 Bulan':
        return 12; // 12 weeks
      case '6 Bulan':
        return 12; // 12 bi-weekly points
      case '1 Tahun':
        return 12; // 12 months
      default:
        return 30;
    }
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon,
      Color color, List<FlSpot> spots) {
    final interval = getDateInterval(selectedPeriod);
    final dataPoints = getDataPoints(selectedPeriod);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 5),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: value,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            TextSpan(
                              text: ' $unit',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Filter dropdown
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200],
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        final now = DateTime.now();
                        final date = now.subtract(Duration(
                            days: ((dataPoints - 1) - value).toInt() *
                                interval.toInt()));
                        return Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(
                            getFormattedDate(date, selectedPeriod),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: color,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.3),
                          color.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipPadding: EdgeInsets.all(8),
                    tooltipMargin: 8,
                    tooltipRoundedRadius: 8,
                    tooltipBorder: BorderSide(
                      color: color.withOpacity(0.2),
                      width: 1,
                    ),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final now = DateTime.now();
                        final date = now.subtract(Duration(
                            days: ((dataPoints - 1) - touchedSpot.x).toInt() *
                                interval.toInt()));
                        String periodLabel = '';
                        if (selectedPeriod == '1 Bulan') {
                          periodLabel =
                              '${DateFormat('dd MMMM yyyy', 'id').format(date)}';
                        } else if (selectedPeriod == '3 Bulan') {
                          periodLabel =
                              'Minggu ${date.difference(date.subtract(Duration(days: date.weekday - 1))).inDays ~/ 7 + 1}\n${DateFormat('MMMM yyyy', 'id').format(date)}';
                        } else if (selectedPeriod == '6 Bulan') {
                          periodLabel =
                              '${DateFormat('dd MMM', 'id').format(date)} - ${DateFormat('dd MMM yyyy', 'id').format(date.add(Duration(days: 13)))}';
                        } else {
                          periodLabel =
                              DateFormat('MMMM yyyy', 'id').format(date);
                        }
                        return LineTooltipItem(
                          '${touchedSpot.y.toInt()} $unit\n$periodLabel',
                          TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
      String title, String value, IconData icon, Color color) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScanHistoryItem(String title, String subtitle, String time) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF5F9F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              color: Color(0xFF4CAF50),
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
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
