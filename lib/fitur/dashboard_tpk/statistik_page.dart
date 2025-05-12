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

  final Color primaryGreen = Color(0xFF2E7D32);
  final Color lightGreen = Color(0xFF81C784);
  final Color darkGreen = Color(0xFF1B5E20);
  final Color accentGreen = Color(0xFFC8E6C9);

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
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      body: Obx(() {
        // Refresh chart data when inventory changes
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart_outlined,
                    size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada data inventory',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return TabBarView(
          controller: _tabController,
          children: [
            // Pie Chart - Jenis Kayu
            _buildPieChartView(),

            // Bar Chart - Batch
            _buildBarChartView(),

            // Stok Detail - Table View
            _buildStockDetailView(),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _controller.refreshInventory(),
        backgroundColor: primaryGreen,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh Data',
      ),
    );
  }

  Widget _buildPieChartView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildStatsHeader('Distribusi Jenis Kayu',
              'Total: ${_controller.totalKayu.value} unit'),
        ),
        Expanded(
          child: _jenisKayuData.isEmpty
              ? _buildNoDataView('jenis kayu')
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 0,
                      sections: _getPieSections(),
                      pieTouchData: PieTouchData(),
                    ),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildLegend(_jenisKayuData),
        ),
      ],
    );
  }

  Widget _buildBarChartView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildStatsHeader('Distribusi Batch Panen',
              'Total batch: ${_controller.jumlahBatch.value}'),
        ),
        Expanded(
          child: _batchData.isEmpty
              ? _buildNoDataView('batch panen')
              : Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 20.0),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.center,
                      maxY: _getMaxBatchValue(),
                      minY: 0,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            String batchName =
                                _getBatchNameForIndex(groupIndex);
                            return BarTooltipItem(
                              '$batchName\n${rod.toY.round()} unit',
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              String text = '';
                              if (value.toInt() < _batchData.length) {
                                String batchName =
                                    _getBatchNameForIndex(value.toInt());
                                text = batchName.substring(
                                    0, min(3, batchName.length));
                                text += '...';
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(text,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              );
                            },
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(value.toInt().toString(),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              );
                            },
                            reservedSize: 30,
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: _getMaxBatchValue() / 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      barGroups: _getBarGroups(),
                    ),
                  ),
                ),
        ),
      ],
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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan judul dan tombol tutup
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Inventory: ${item.namaKayu}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),

              const Divider(),

              // Gambar
              if (item.imageUrl.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported,
                            size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                Center(
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: accentGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.forest,
                      size: 80,
                      color: primaryGreen,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Informasi detail
              _buildDetailRow('ID', item.id),
              _buildDetailRow('Nama Kayu', item.namaKayu),
              _buildDetailRow('Jenis Kayu', item.jenisKayu),
              _buildDetailRow('Batch', item.batchPanen),
              _buildDetailRow('Stok', '${item.jumlahStok} unit'),

              const SizedBox(height: 20),

              // Tombol aksi
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      _controller.editItem(index);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      _controller.viewItemDetails(index);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                    ),
                    child: const Text(
                      'Lihat Detail Lengkap',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk baris informasi pada dialog detail
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: Colors.black87,
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
    List<Widget> legendItems = [];
    int index = 0;

    data.forEach((key, value) {
      final color = _getPieChartColor(index);

      legendItems.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(key.isEmpty ? 'Tidak Spesifik' : key)),
            Text(
              '$value unit',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ));

      index++;
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legenda:',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          ...legendItems,
        ],
      ),
    );
  }

  // Helper methods for charts
  List<PieChartSectionData> _getPieSections() {
    List<PieChartSectionData> sections = [];
    int index = 0;

    _jenisKayuData.forEach((jenis, jumlah) {
      final double percentage = (jumlah / _controller.totalKayu.value) * 100;
      final color = _getPieChartColor(index);

      sections.add(
        PieChartSectionData(
          value: jumlah.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          color: color,
          radius: 100,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
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
                colors: [lightGreen, primaryGreen],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );

      index++;
    });

    return groups;
  }

  Color _getPieChartColor(int index) {
    // Liste colori verdi per il grafico a torta
    final List<Color> colors = [
      primaryGreen,
      lightGreen,
      darkGreen,
      const Color(0xFF4CAF50), // Verde standard
      const Color(0xFF8BC34A), // Verde lime
      const Color(0xFF009688), // Verde turchese
    ];

    return colors[index % colors.length];
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
