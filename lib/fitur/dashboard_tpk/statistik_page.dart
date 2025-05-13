import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/dashboard_tpk/controller_inventory_kayu.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class StatistikPage extends StatefulWidget {
  static String routeName = "/statistik";

  const StatistikPage({Key? key}) : super(key: key);

  @override
  State<StatistikPage> createState() => _StatistikPageState();
}

class _StatistikPageState extends State<StatistikPage>
    with SingleTickerProviderStateMixin {
  final InventoryKayuController _controller =
      Get.find<InventoryKayuController>();
  late TabController _tabController;

  // Data grouping variables
  final Map<String, int> _jenisKayuData = {};
  final Map<String, int> _batchData = {};
  final Map<String, int> _stockByMonthData = {};

  // Updated color palette based on design system
  final Color primaryGreen = Color(0xFF4CAF50);
  final Color darkGreen = Color(0xFF2E7D32);
  final Color lightGreen = Color(0xFF66BB6A);
  final Color accentGreen = Color(0xFF8BC34A);
  final Color backgroundGreen = Color(0xFFE8F5E9);

  final List<Color> chartGradients = [
    Color(0xFF4CAF50),
    Color(0xFF66BB6A),
    Color(0xFF81C784),
    Color(0xFF8BC34A),
    Color(0xFF9CCC65),
    Color(0xFFAED581),
  ];

  // Track touched section index for pie chart
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _prepareChartData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _prepareChartData() {
    // Bersihkan data lama
    _jenisKayuData.clear();
    _batchData.clear();
    _stockByMonthData.clear();

    for (var item in _controller.inventoryItems) {
      // Proses data untuk pie chart jenis kayu
      if (_jenisKayuData.containsKey(item.jenisKayu)) {
        _jenisKayuData[item.jenisKayu] =
            _jenisKayuData[item.jenisKayu]! + item.jumlahStok;
      } else {
        _jenisKayuData[item.jenisKayu] = item.jumlahStok;
      }

      // Proses data untuk bar chart batch
      final batchKey =
          item.batchPanen.isEmpty ? 'Tanpa Batch' : item.batchPanen;
      if (_batchData.containsKey(batchKey)) {
        _batchData[batchKey] = _batchData[batchKey]! + item.jumlahStok;
      } else {
        _batchData[batchKey] = item.jumlahStok;
      }

      // Kelompokkan stok berdasarkan bulan (menggunakan data batch sebagai pengelompokan tambahan)
      // Dengan asumsi format batch mencakup informasi tanggal/waktu yang relevan
      // Jika tidak, ini bisa diganti dengan data lain yang relevan dari InventoryItem
      String monthKey = 'Total';

      // Tambahkan ke data stok per bulan
      if (_stockByMonthData.containsKey(monthKey)) {
        _stockByMonthData[monthKey] =
            _stockByMonthData[monthKey]! + item.jumlahStok;
      } else {
        _stockByMonthData[monthKey] = item.jumlahStok;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Statistik Inventory',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
            fontSize: 18,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: darkGreen),
            onPressed: () => _controller.refreshInventory(),
            tooltip: 'Refresh Data',
          ),
          SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: darkGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryGreen,
          indicatorWeight: 3,
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: 'Jenis Kayu'),
            Tab(text: 'Batch'),
            Tab(text: 'Detail'),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
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
        child: Obx(() {
          if (_controller.inventoryItems.isNotEmpty) {
            _prepareChartData();
          }

          if (_controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
              ),
            );
          }

          if (_controller.inventoryItems.isEmpty) {
            return _buildEmptyState();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildPieChartView(),
              _buildBarChartView(),
              _buildStockDetailView(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bar_chart_outlined,
              size: 80,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada data inventory',
            style: TextStyle(
              fontSize: 18,
              color: darkGreen,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan item inventory untuk melihat statistik',
            style: TextStyle(
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
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
                _buildStatsHeader('Distribusi Jenis Kayu',
                    'Total: ${_controller.totalKayu.value} unit'),
                SizedBox(height: 20),
                Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: _jenisKayuData.isEmpty
                      ? _buildNoDataView('jenis kayu')
                      : Stack(
                          children: [
                            PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 60,
                                sections: _getPieSections(),
                                pieTouchData: PieTouchData(
                                  touchCallback:
                                      (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection ==
                                              null) {
                                        touchedIndex = -1;
                                        return;
                                      }
                                      touchedIndex = pieTouchResponse
                                          .touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Total',
                                    style: TextStyle(
                                      color: darkGreen,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${_controller.totalKayu.value}',
                                    style: TextStyle(
                                      color: primaryGreen,
                                      fontSize: 24,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'unit',
                                    style: TextStyle(
                                      color: darkGreen,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                if (touchedIndex != -1 && _jenisKayuData.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 16),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFF81C784), width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: chartGradients[
                                touchedIndex % chartGradients.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _jenisKayuData.keys.elementAt(touchedIndex),
                                style: TextStyle(
                                  color: darkGreen,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                '${_jenisKayuData.values.elementAt(touchedIndex)} unit (${(_jenisKayuData.values.elementAt(touchedIndex) / _controller.totalKayu.value * 100).toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildLegend(_jenisKayuData),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBarChartView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
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
                _buildStatsHeader('Distribusi Batch Panen',
                    'Total batch: ${_controller.jumlahBatch.value}'),
                SizedBox(height: 20),
                Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: _batchData.isEmpty
                      ? _buildNoDataView('batch panen')
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _getMaxBatchValue(),
                            minY: 0,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  String batchName =
                                      _getBatchNameForIndex(groupIndex);
                                  return BarTooltipItem(
                                    '$batchName\n${rod.toY.round()} unit',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  );
                                },
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                tooltipPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                tooltipMargin: 8,
                                tooltipRoundedRadius: 8,
                                tooltipHorizontalAlignment:
                                    FLHorizontalAlignment.center,
                                tooltipHorizontalOffset: 0,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= _batchData.length) {
                                      return SizedBox();
                                    }
                                    String batchName =
                                        _getBatchNameForIndex(value.toInt());
                                    return Transform.rotate(
                                      angle:
                                          -0.5, // Rotate labels slightly for better readability
                                      child: Container(
                                        padding: EdgeInsets.only(top: 8),
                                        width: 60,
                                        child: Text(
                                          batchName.length > 8
                                              ? batchName.substring(0, 8) +
                                                  '...'
                                              : batchName,
                                          style: TextStyle(
                                            color: darkGreen,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Poppins',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  },
                                  reservedSize: 40,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: Text(
                                        value.toInt().toString(),
                                        style: TextStyle(
                                          color: darkGreen,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    );
                                  },
                                  reservedSize: 40,
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: _getMaxBatchValue() / 5,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.shade200,
                                  strokeWidth: 1,
                                  dashArray: [5, 5],
                                );
                              },
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                left: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                            ),
                            barGroups: _getBarGroups(),
                          ),
                        ),
                ),
              ],
            ),
          ),
          // Legend for bar chart
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Batch',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: darkGreen,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 12),
                ..._batchData.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: chartGradients[
                                _batchData.keys.toList().indexOf(entry.key) %
                                    chartGradients.length],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 13,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value} unit',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: darkGreen,
                            fontSize: 13,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  // Menampilkan detail item saat diklik
  void _showItemDetail(InventoryItem item, int index) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: 500,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan judul dan tombol tutup
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Detail Inventory: ${item.namaKayu}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gambar
                      if (item.imageUrl.isNotEmpty)
                        Container(
                          height: 250,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 24),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 250,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.forest,
                            size: 80,
                            color: Color(0xFF4CAF50),
                          ),
                        ),

                      // Informasi detail dalam card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('ID', item.id),
                            _buildDetailRow('Nama Kayu', item.namaKayu),
                            _buildDetailRow('Jenis Kayu', item.jenisKayu),
                            _buildDetailRow('Batch', item.batchPanen),
                            _buildDetailRow('Stok', '${item.jumlahStok} unit'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer dengan tombol
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        _controller.viewItemDetails(index);
                      },
                      icon:
                          Icon(Icons.visibility, size: 18, color: Colors.white),
                      label: Text(
                        'Lihat Detail Lengkap',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CAF50),
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  // Widget untuk baris informasi pada dialog detail
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                color: Color(0xFF424242),
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockDetailView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildStatsHeader('Detail Stok per Item',
              'Total: ${_controller.totalKayu.value} unit'),
        ),
        Expanded(
          child: _controller.inventoryItems.isEmpty
              ? _buildNoDataView('item kayu')
              : ListView.builder(
                  itemCount: _controller.inventoryItems.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final item = _controller.inventoryItems[index];
                    return InkWell(
                      onTap: () => _showItemDetail(item, index),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Image if available
                              if (item.imageUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[200],
                                      child: const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: lightGreen.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child:
                                      Icon(Icons.forest, color: primaryGreen),
                                ),

                              const SizedBox(width: 16),

                              // Item details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.namaKayu.isEmpty
                                          ? 'Tanpa Nama'
                                          : item.namaKayu,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Jenis: ${item.jenisKayu}'),
                                    Text(
                                        'Batch: ${item.batchPanen.isEmpty ? 'Tanpa Batch' : item.batchPanen}'),
                                  ],
                                ),
                              ),

                              // Stock counter
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: primaryGreen,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${item.jumlahStok}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataView(String dataType) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data $dataType tersedia',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Map<String, int> data) {
    return Container(
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
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legenda',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: darkGreen,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 12),
          ...data.entries.map((entry) {
            final index = data.keys.toList().indexOf(entry.key);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: chartGradients[index % chartGradients.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key.isEmpty ? 'Tidak Spesifik' : entry.key,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value} unit',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: darkGreen,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Helper methods for charts
  List<PieChartSectionData> _getPieSections() {
    List<PieChartSectionData> sections = [];
    int index = 0;

    _jenisKayuData.forEach((jenis, jumlah) {
      final isTouched = index == touchedIndex;
      final double fontSize = isTouched ? 16 : 14;
      final double radius = isTouched ? 110 : 100;
      final double percentage = (jumlah / _controller.totalKayu.value) * 100;
      final color = chartGradients[index % chartGradients.length];

      sections.add(
        PieChartSectionData(
          value: jumlah.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          color: color,
          radius: radius,
          titleStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
            fontFamily: 'Poppins',
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          titlePositionPercentageOffset: 0.6,
          showTitle: true,
        ),
      );

      index++;
    });

    return sections;
  }

  List<BarChartGroupData> _getBarGroups() {
    List<BarChartGroupData> groups = [];
    int index = 0;

    _batchData.forEach((batch, jumlah) {
      groups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: jumlah.toDouble(),
              gradient: LinearGradient(
                colors: [
                  chartGradients[index % chartGradients.length],
                  chartGradients[(index + 1) % chartGradients.length],
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 16,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(4),
                bottom: Radius.circular(0),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: _getMaxBatchValue(),
                color: Colors.grey.shade100,
              ),
            ),
          ],
        ),
      );

      index++;
    });

    return groups;
  }

  double _getMaxBatchValue() {
    if (_batchData.isEmpty) return 100.0;
    return (_batchData.values.reduce((a, b) => a > b ? a : b) * 1.2).toDouble();
  }

  String _getBatchNameForIndex(int index) {
    if (index >= _batchData.length) return '';
    return _batchData.keys.elementAt(index);
  }

  int min(int a, int b) {
    return a < b ? a : b;
  }
}
