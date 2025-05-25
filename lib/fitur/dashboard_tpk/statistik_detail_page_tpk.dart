import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_green_track/controllers/dashboard_tpk/dashboard_tpk_controller.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class StatistikDetailPageTPK extends StatefulWidget {
  final String type;

  StatistikDetailPageTPK({Key? key, required this.type}) : super(key: key);

  @override
  _StatistikDetailPageTPKState createState() => _StatistikDetailPageTPKState();
}

class _StatistikDetailPageTPKState extends State<StatistikDetailPageTPK> {
  final TPKDashboardController controller = Get.find<TPKDashboardController>();
  String selectedPeriod = '6 Bulan';
  final List<String> periods = ['1 Bulan', '3 Bulan', '6 Bulan', '1 Tahun'];

  // Tambahkan RxString untuk menyimpan detail point yang dipilih
  final RxString selectedPointDetail = ''.obs;

  @override
  void initState() {
    super.initState();
    // Inisialisasi format tanggal untuk locale Indonesia
    initializeDateFormatting('id', null);
  }

  void updateSelectedPoint(DateTime date, double value,
      {bool isSelected = true}) {
    if (isSelected) {
      selectedPointDetail.value =
          '${value.toInt()} ${widget.type == 'inventory' ? 'kayu' : 'pemindaian'} pada ${DateFormat('dd MMM yyyy', 'id').format(date)}';
    } else {
      selectedPointDetail.value = '';
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
        return 1; // Harian
      case '3 Bulan':
        return 7; // Mingguan
      case '6 Bulan':
        return 14; // Dua mingguan
      case '1 Tahun':
        return 30; // Bulanan
      default:
        return 1;
    }
  }

  int getDataPoints(String period) {
    switch (period) {
      case '1 Bulan':
        return 30; // 30 hari
      case '3 Bulan':
        return 12; // 12 minggu
      case '6 Bulan':
        return 12; // 12 periode dua mingguan
      case '1 Tahun':
        return 12; // 12 bulan
      default:
        return 30;
    }
  }

  String formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  double calculateYAxisInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 5;

    double maxY = spots
        .map((spot) => spot.y)
        .reduce((max, value) => value > max ? value : max);
    double minY = spots
        .map((spot) => spot.y)
        .reduce((min, value) => value < min ? value : min);
    double range = maxY - minY;

    if (range <= 10) return 1;
    if (range <= 50) return 5;
    if (range <= 100) return 10;
    if (range <= 500) return 50;
    if (range <= 1000) return 100;
    if (range <= 5000) return 500;
    if (range <= 10000) return 1000;
    return 5000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == 'inventory'
              ? 'Detail Statistik Inventory'
              : 'Detail Statistik Pemindaian',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          // Period Selector
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedPeriod,
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.white),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                dropdownColor: Color(0xFF4CAF50),
                items: periods.map((String period) {
                  return DropdownMenuItem<String>(
                    value: period,
                    child: Text(period),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedPeriod = newValue;
                      controller.refreshDashboardData();
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.inventory_2_rounded,
                          title: "Total Inventory",
                          value: controller.totalWood.value,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.qr_code_scanner_rounded,
                          title: "Total Dipindai",
                          value: controller.scannedWood.value,
                          color: Color(0xFF66BB6A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.category_rounded,
                          title: "Total Batch",
                          value: controller.totalBatch.value,
                          color: Color(0xFF81C784),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.trending_up_rounded,
                          title: "Pertumbuhan",
                          value: controller.woodStatTrend.value,
                          color: Color(0xFF8BC34A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildHeaderCard(),
            _buildChartSection(),
            _buildStatisticsDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 3),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4CAF50).withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 3),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Obx(() => Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.type == 'inventory'
                      ? Icons.inventory_2_rounded
                      : Icons.qr_code_scanner_rounded,
                  color: Color(0xFF4CAF50),
                  size: 16,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.type == 'inventory'
                          ? controller.totalWood.value
                          : controller.scannedWood.value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.type == 'inventory'
                          ? 'Total Inventory Kayu'
                          : 'Total Kayu Dipindai',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.type == 'inventory'
                          ? controller.woodStatTrend.value
                          : controller.scanStatTrend.value,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }

  Widget _buildChartSection() {
    final interval = getDateInterval(selectedPeriod);
    final dataPoints = getDataPoints(selectedPeriod);

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4CAF50).withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 3),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF4CAF50),
                  size: 16,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Grafik ${selectedPeriod} Terakhir',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 250,
            child: Obx(() => LineChart(
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
                      leftTitles: AxisTitles(
                        axisNameWidget: Text(
                          widget.type == 'inventory'
                              ? 'Jumlah Kayu'
                              : 'Jumlah Pemindaian',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          interval: calculateYAxisInterval(
                            widget.type == 'inventory'
                                ? controller.inventorySpots
                                : controller.revenueSpots,
                          ),
                          getTitlesWidget: (value, meta) {
                            return Text(
                              formatNumber(value),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: interval,
                          getTitlesWidget: (value, meta) {
                            final now = DateTime.now();
                            final date = now.subtract(Duration(
                                days: ((dataPoints - 1) - value).toInt() *
                                    interval.toInt()));
                            return Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                getFormattedDate(date, selectedPeriod),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 9,
                                  fontFamily: 'Poppins',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                          reservedSize: 25,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: widget.type == 'inventory'
                            ? controller.inventorySpots
                            : controller.revenueSpots,
                        isCurved: true,
                        color: Color(0xFF4CAF50),
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: Color(0xFF4CAF50),
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF4CAF50).withOpacity(0.3),
                              Color(0xFF4CAF50).withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        tooltipPadding: EdgeInsets.all(8),
                        tooltipMargin: 8,
                        tooltipRoundedRadius: 8,
                        tooltipBorder: BorderSide(
                          color: Color(0xFF4CAF50).withOpacity(0.2),
                          width: 1,
                        ),
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          if (touchedSpots.isEmpty) return [];

                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            final now = DateTime.now();
                            final date = now.subtract(Duration(
                                days:
                                    ((dataPoints - 1) - touchedSpot.x).toInt() *
                                        interval.toInt()));

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              // Update selected point detail in the next frame
                              selectedPointDetail.value =
                                  '${touchedSpot.y.toInt()} ${widget.type == 'inventory' ? 'kayu' : 'pemindaian'} pada ${DateFormat('dd MMM yyyy', 'id').format(date)}';
                            });

                            return LineTooltipItem(
                              '${touchedSpot.y.toInt()} ${widget.type == 'inventory' ? 'kayu' : 'pemindaian'}\n${DateFormat('dd MMM yyyy', 'id').format(date)}',
                              TextStyle(
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                fontFamily: 'Poppins',
                              ),
                            );
                          }).toList();
                        },
                      ),
                      touchCallback: (FlTouchEvent event,
                          LineTouchResponse? touchResponse) {
                        if (event is FlPanEndEvent ||
                            event is FlPointerExitEvent) {
                          // Only clear when actually leaving the chart area
                          selectedPointDetail.value = '';
                        } else if (event is FlTapUpEvent) {
                          if (touchResponse?.lineBarSpots == null ||
                              touchResponse!.lineBarSpots!.isEmpty) {
                            // Clear only if tapped outside any data point
                            selectedPointDetail.value = '';
                          }
                        }
                      },
                    ),
                  ),
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsDetails() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4CAF50).withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 3),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: Color(0xFF4CAF50),
                  size: 16,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Ringkasan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Obx(() => Column(
                children: [
                  _buildStatItem(
                    icon: Icons.inventory_2_rounded,
                    title: 'Total Batch',
                    value: controller.totalBatch.value,
                  ),
                  SizedBox(height: 12),
                  _buildStatItem(
                    icon: widget.type == 'inventory'
                        ? Icons.trending_up
                        : Icons.qr_code_scanner_rounded,
                    title: widget.type == 'inventory'
                        ? 'Pertumbuhan'
                        : 'Pemindaian Minggu Ini',
                    value: widget.type == 'inventory'
                        ? controller.woodStatTrend.value
                        : controller.scanStatTrend.value,
                  ),
                  if (selectedPointDetail.value.isNotEmpty) ...[
                    SizedBox(height: 12),
                    _buildStatItem(
                      icon: Icons.touch_app_rounded,
                      title: 'Detail Point',
                      value: selectedPointDetail.value,
                    ),
                  ],
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Color(0xFF4CAF50),
            size: 16,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aktivitas Terkait',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          SizedBox(height: 20),
          Obx(() {
            final activities = controller.recentActivities
                .where((activity) => widget.type == 'inventory'
                    ? activity.namaAktivitas.toLowerCase().contains('inventory')
                    : activity.namaAktivitas.toLowerCase().contains('scan'))
                .take(5)
                .toList();

            return Column(
              children: activities
                  .map((activity) => Container(
                        margin: EdgeInsets.only(bottom: 15),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                activity.icon ?? Icons.article_rounded,
                                color: Color(0xFF4CAF50),
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity.namaAktivitas,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    activity.time ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}
