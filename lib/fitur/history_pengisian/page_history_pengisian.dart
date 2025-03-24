import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/history_pengisian/history_pengisian_controller.dart';
import 'package:flutter_green_track/fitur/history_pengisian/page_history_detail_bibit.dart';
import 'package:get/get.dart';

class HistoryPengisianPage extends StatefulWidget {
  static String routeName = "/history-pengisian";

  @override
  _HistoryPengisianPageState createState() => _HistoryPengisianPageState();
}

class _HistoryPengisianPageState extends State<HistoryPengisianPage>
    with SingleTickerProviderStateMixin {
  final HistoryPengisianController controller =
      Get.put(HistoryPengisianController());
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'History Pengisian',
          style: TextStyle(
            color: Colors.green.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false, // Posisi judul di start
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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

          // Content
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                margin: EdgeInsets.all(16),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.green.shade800,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: Colors.green.shade800,
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      width: 3.0,
                      color: Colors.green.shade800,
                    ),
                    insets: EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  tabs: [
                    Tab(text: 'Hari Ini'),
                    Tab(text: 'Kemarin'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Hari Ini tab
                    Obx(() => _buildBibitList(controller.hariIniList)),

                    // Kemarin tab
                    Obx(() => _buildBibitList(controller.kemarinList)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBibitList(List<BibitModel> bibitList) {
    return bibitList.isEmpty
        ? Center(child: Text('Tidak ada data'))
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: bibitList.length,
            itemBuilder: (context, index) {
              final bibit = bibitList[index];
              return _buildBibitCard(bibit);
            },
          );
  }

  Widget _buildBibitCard(BibitModel bibit) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Color(0xFFB9EEC4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => Get.toNamed(
          DetailBibitPage.routeName,
          arguments: bibit,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon untuk gambar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Color(0xFFEDF7ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.eco,
                  color: Colors.green.shade700,
                  size: 36,
                ),
              ),

              SizedBox(width: 16),

              // Informasi bibit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bibit.nama,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Varietas: ${bibit.varietas}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Usia: ${bibit.usia}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Tombol panah dengan background lingkaran
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
