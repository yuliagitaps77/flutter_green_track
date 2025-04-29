import 'package:flutter/material.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/controller/controller_page_nav_bibit.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/model/model_bibit.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DetailPage extends StatelessWidget {
  final String barcodeId;
  final BibitController bibitController = Get.find<BibitController>();

  DetailPage({Key? key, required this.barcodeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Bibit'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<Bibit?>(
        future: bibitController.getBibitByBarcode(barcodeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Bibit tidak ditemukan'));
          } else {
            final bibit = snapshot.data!;
            return _buildDetailContent(context, bibit);
          }
        },
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, Bibit bibit) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carousel gambar bibit
          if (bibit.gambarImage.isNotEmpty)
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: bibit.gambarImage.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.network(
                      bibit.gambarImage[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.error, size: 40),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            )
          else
            Card(
              elevation: 4,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Informasi utama bibit
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bibit.namaBibit,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPropertyRow('Jenis Bibit', bibit.jenisBibit),
                  _buildPropertyRow('Varietas', bibit.varietas),
                  _buildPropertyRow('Usia', '${bibit.usia} hari'),
                  _buildPropertyRow('Tinggi', '${bibit.tinggi} cm'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Informasi kondisi
          _buildSectionCard(
            'Kondisi Bibit',
            [
              _buildPropertyRow('Kondisi', bibit.kondisi),
              _buildPropertyRow('Status Hama', bibit.statusHama),
              _buildPropertyRow('Media Tanam', bibit.mediaTanam),
              _buildPropertyRow('Nutrisi', bibit.nutrisi),
            ],
          ),
          const SizedBox(height: 16),

          // Informasi asal & lokasi
          _buildSectionCard(
            'Asal & Lokasi',
            [
              _buildPropertyRow('Asal Bibit', bibit.asalBibit),
              _buildPropertyRow('KPH', bibit.kph),
              _buildPropertyRow('BKPH', bibit.bkph),
              _buildPropertyRow('RKPH', bibit.rkph),
            ],
          ),
          const SizedBox(height: 16),

          // Informasi tambahan
          _buildSectionCard(
            'Informasi Tambahan',
            [
              _buildPropertyRow('Produktivitas', bibit.produktivitas),
              _buildPropertyRow(
                'Tanggal Pembibitan',
                DateFormat('dd MMMM yyyy').format(bibit.tanggalPembibitan),
              ),
              _buildPropertyRow(
                'Terakhir Diperbarui',
                DateFormat('dd MMMM yyyy').format(bibit.updatedAt),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Catatan
          if (bibit.catatan.isNotEmpty)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catatan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bibit.catatan,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 30),

          // Tombol aksi
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    // Fitur berbagi informasi bibit
                    Get.snackbar(
                      'Info',
                      'Berbagi informasi bibit ${bibit.namaBibit}',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Bagikan', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    // Fitur untuk mengarahkan ke URL terkait bibit
                    if (bibit.urlBibit.isNotEmpty) {
                      // Misalnya launch URL
                      Get.snackbar(
                        'Info',
                        'Membuka URL: ${bibit.urlBibit}',
                        backgroundColor: Colors.blue,
                        colorText: Colors.white,
                      );
                    } else {
                      Get.snackbar(
                        'Info',
                        'URL tidak tersedia',
                        backgroundColor: Colors.orange,
                        colorText: Colors.white,
                      );
                    }
                  },
                  icon: const Icon(Icons.link),
                  label:
                      const Text('Buka Link', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
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
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
