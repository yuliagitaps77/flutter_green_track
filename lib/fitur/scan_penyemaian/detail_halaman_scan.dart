import 'package:flutter/material.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/controller/controller_page_nav_bibit.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/model/model_bibit.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DetailPage extends StatelessWidget {
  final String barcodeId;
  final BibitController bibitController = Get.find<BibitController>();
  final GlobalKey qrKey = GlobalKey();

  DetailPage({Key? key, required this.barcodeId}) : super(key: key);

  // Function to export QR code
  void _exportQR(String data) {
    Get.snackbar(
      'QR Code',
      'QR Code berhasil diexport',
      backgroundColor: Color(0xFF4CAF50),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(20),
      borderRadius: 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

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
        child: FutureBuilder<Bibit?>(
          future: bibitController.getBibitByBarcode(barcodeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4CAF50),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                    SizedBox(height: 16),
                    Text(
                      'Terjadi Kesalahan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF424242),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Bibit Tidak Ditemukan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              final bibit = snapshot.data!;
              return _buildDetailContent(context, bibit, screenWidth);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDetailContent(
      BuildContext context, Bibit bibit, double screenWidth) {
    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        // App Bar with image
        SliverAppBar(
          expandedHeight: 240.0,
          floating: false,
          pinned: true,
          backgroundColor: Color(0xFF2E7D32),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              bibit.namaBibit,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3.0,
                    color: Color.fromARGB(130, 0, 0, 0),
                  ),
                ],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Background image or color
                bibit.gambarImage.isNotEmpty
                    ? Image.network(
                        bibit.gambarImage[0],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Color(0xFF4CAF50).withOpacity(0.3),
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Color(0xFF4CAF50).withOpacity(0.3),
                        child: Center(
                          child: Icon(
                            Icons.forest,
                            size: 80,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                // Gradient overlay for better text visibility
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                      stops: [0.6, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          leading: IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: Color(0xFF2E7D32), size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick summary card
                Container(
                  width: double.infinity,
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
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(0xFFEDF7ED),
                            radius: 24,
                            child: Icon(
                              Icons.spa,
                              color: Color(0xFF4CAF50),
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bibit.namaBibit,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                Text(
                                  bibit.jenisBibit,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF66BB6A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickInfoItem(Icons.calendar_today_outlined,
                              '${bibit.usia}', 'Usia (hari)'),
                          _buildQuickInfoItem(
                              Icons.height, '${bibit.tinggi}', 'Tinggi (cm)'),
                          _buildQuickInfoItem(Icons.health_and_safety_outlined,
                              bibit.kondisi, 'Kondisi'),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // QR Code Section
                Container(
                  width: double.infinity,
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
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        "QR Code Bibit",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: RepaintBoundary(
                          key: qrKey,
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Color(0xFFEDF7ED),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                QrImageView(
                                  data: bibit.id,
                                  version: QrVersions.auto,
                                  size: screenWidth * 0.5,
                                  backgroundColor: Colors.white,
                                  foregroundColor: Color(0xFF2E7D32),
                                  errorStateBuilder: (cxt, err) {
                                    return Center(
                                      child: Text(
                                        "QR Error: $err",
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "ID Bibit",
                                  style: TextStyle(
                                    color: Color(0xFF424242),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  bibit.id,
                                  style: TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: SizedBox(
                          width: screenWidth * 0.6,
                          child: ElevatedButton.icon(
                            onPressed: () => _exportQR(bibit.id),
                            icon: const Icon(Icons.download_rounded),
                            label: const Text("Export QR"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Detail Information
                _buildDetailSection(
                  "Detail Bibit",
                  Icons.info_outline,
                  [
                    _buildInfoRow("Varietas", bibit.varietas),
                    _buildInfoRow("Jenis Bibit", bibit.jenisBibit),
                    _buildInfoRow("Usia", "${bibit.usia} hari"),
                    _buildInfoRow("Tinggi", "${bibit.tinggi} cm"),
                    _buildInfoRow("Kondisi", bibit.kondisi),
                  ],
                ),

                SizedBox(height: 20),

                _buildDetailSection(
                  "Kondisi Bibit",
                  Icons.health_and_safety_outlined,
                  [
                    _buildInfoRow("Status Hama", bibit.statusHama),
                    _buildInfoRow("Media Tanam", bibit.mediaTanam),
                    _buildInfoRow("Nutrisi", bibit.nutrisi),
                  ],
                ),

                SizedBox(height: 20),

                _buildDetailSection(
                  "Asal & Lokasi",
                  Icons.location_on_outlined,
                  [
                    _buildInfoRow("Asal Bibit", bibit.asalBibit),
                    _buildInfoRow("KPH", bibit.kph),
                    _buildInfoRow("BKPH", bibit.bkph),
                    _buildInfoRow("RKPH", bibit.rkph),
                  ],
                ),

                SizedBox(height: 20),

                _buildDetailSection(
                  "Informasi Tambahan",
                  Icons.more_horiz,
                  [
                    _buildInfoRow("Produktivitas", bibit.produktivitas),
                    _buildInfoRow(
                      "Tanggal Pembibitan",
                      DateFormat('dd MMMM yyyy')
                          .format(bibit.tanggalPembibitan),
                    ),
                    _buildInfoRow("URL Bibit",
                        bibit.urlBibit.isNotEmpty ? bibit.urlBibit : "-"),
                    _buildInfoRow(
                      "Terakhir Diperbarui",
                      DateFormat('dd MMMM yyyy').format(bibit.updatedAt),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Catatan
                if (bibit.catatan.isNotEmpty)
                  Container(
                    width: double.infinity,
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
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notes_rounded,
                              color: Color(0xFF4CAF50),
                              size: 24,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Catatan",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        Divider(
                            height: 30, thickness: 1, color: Color(0xFFEDF7ED)),
                        Text(
                          bibit.catatan,
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF424242),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 20),

                // Image Gallery
                if (bibit.gambarImage.length > 1)
                  Container(
                    width: double.infinity,
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
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.photo_library_rounded,
                              color: Color(0xFF4CAF50),
                              size: 24,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Galeri Foto",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Container(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: BouncingScrollPhysics(),
                            itemCount: bibit.gambarImage.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 120,
                                margin: EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    bibit.gambarImage[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 30,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFFEDF7ED),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Color(0xFF4CAF50),
            size: 20,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailSection(
      String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
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
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          Divider(height: 30, thickness: 1, color: Color(0xFFEDF7ED)),
          ...children
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
