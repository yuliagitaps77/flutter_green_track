import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_green_track/fitur/dashboard_penyemaian/page_cetak_bibit.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/controller/controller_page_nav_bibit.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/model/model_bibit.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

class BibitDetailPage extends StatefulWidget {
  static String routeName = "/BibitDetailPage";

  const BibitDetailPage({Key? key}) : super(key: key);

  @override
  State<BibitDetailPage> createState() => _BibitDetailPageState();
}

class _BibitDetailPageState extends State<BibitDetailPage> {
  late Bibit bibit;
  final GlobalKey qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    bibit = Get.arguments as Bibit;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
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
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: bibit.gambarImage.isNotEmpty
                      ? Image.network(
                          bibit.gambarImage.first,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Container(
                          color: Colors.green.withOpacity(0.1),
                          child: const Icon(
                            Icons.park,
                            size: 100,
                            color: Colors.green,
                          ),
                        ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.green),
                  onPressed: () => Get.back(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bibit.namaBibit,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.tag, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text("Varietas: ${bibit.varietas}"),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.height,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text("Tinggi: ${bibit.tinggi} cm"),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text("Usia: ${bibit.usia} hari"),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Text("Kondisi: ${bibit.kondisi}"),
                        ],
                      ),
                      const Divider(height: 32, thickness: 1),

                      // Lokasi Tanam
                      const Text(
                        "Lokasi Tanam",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("KPH: ${bibit.kph}"),
                      Text("BKPH: ${bibit.bkph}"),
                      Text("RKPH: ${bibit.rkph}"),
                      const Divider(height: 32, thickness: 1),

                      // Catatan
                      const Text(
                        "Catatan",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 24),
                      const Text(
                        "QR Code",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: RepaintBoundary(
                          key: qrKey,
                          child: QrImageView(
                            data: bibit.id,
                            version: QrVersions.auto,
                            size: 200.0,
                            gapless: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _exportQR(bibit.id),
                          icon: const Icon(Icons.download),
                          label: const Text("Export QR"),
                        ),
                      ),

                      Text(
                        bibit.catatan.isNotEmpty
                            ? bibit.catatan
                            : "Tidak ada catatan khusus.",
                        style: TextStyle(color: Colors.grey[800]),
                      ),

                      const SizedBox(height: 16),

                      // Produktivitas
                      const Text(
                        "Produktivitas",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bibit.produktivitas.isNotEmpty
                            ? bibit.produktivitas
                            : "Belum ada informasi produktivitas.",
                        style: TextStyle(color: Colors.grey[800]),
                      ),

                      const SizedBox(height: 32),
                      // Tombol Edit & Hapus
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.edit, color: Colors.green),
                            label: const Text("Edit"),
                            onPressed: () {
                              Get.toNamed(
                                CetakBarcodeBibitPage.routeName,
                                arguments:
                                    bibit, // kirim data Bibit sebagai argumen
                              );
                            },
                          ),
                          OutlinedButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text("Hapus"),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Konfirmasi"),
                                    content: const Text(
                                        "Yakin ingin menghapus bibit ini?"),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Batal")),
                                      ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("Hapus")),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  final controller =
                                      Get.find<BibitController>();
                                  await controller
                                      .hapusBibitFromDatabase(bibit.id);
                                  Get.back();
                                  Get.snackbar(
                                      "Sukses", "Bibit berhasil dihapus.");
                                }
                              }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportQR(String name) async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      Get.snackbar("Akses ditolak", "Tidak bisa menyimpan QR tanpa izin.");
      return;
    }

    try {
      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/qr_$name.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      await ImageGallerySaver.saveFile(file.path);
      Get.snackbar("Sukses", "QR disimpan ke galeri.");
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan QR: $e");
    }
  }
}
