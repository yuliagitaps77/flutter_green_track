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
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
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

  // Define constant colors based on GreenTracks style guide
  final Color primaryGreen = const Color(0xFF4CAF50);
  final Color darkGreen = const Color(0xFF2E7D32);
  final Color backgroundColor = Colors.white;
  final Color inactiveColor = const Color(0xFF757575); // Grey 600
  final Color shadowColor = Colors.black.withOpacity(0.1);
  final Color selectedBackgroundColor =
      const Color(0xFF4CAF50).withOpacity(0.1);

  @override
  void initState() {
    super.initState();
    bibit = Get.arguments as Bibit;
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    // Responsive font sizes
    final double titleFontSize = isSmallScreen ? 22 : 24;
    final double sectionTitleSize = isSmallScreen ? 16 : 18;
    final double bodyTextSize = isSmallScreen ? 14 : 16;
    final double smallTextSize = isSmallScreen ? 12 : 14;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: 1.0, // Lock text scale factor for consistency
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Background with gradient as per style guide
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
              physics: const BouncingScrollPhysics(),
              slivers: [
                // SliverAppBar with improved elevation and transition
                SliverAppBar(
                  expandedHeight: screenWidth * 0.7, // Responsive height
                  pinned: true,
                  backgroundColor: backgroundColor,
                  elevation: 2,
                  shadowColor: shadowColor,
                  flexibleSpace: FlexibleSpaceBar(
                    background: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: 1.0,
                      child: bibit.gambarImage.isNotEmpty
                          ? Image.network(
                              bibit.gambarImage.first,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: selectedBackgroundColor,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: primaryGreen,
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: selectedBackgroundColor,
                                  child: Icon(
                                    Icons.park,
                                    size: 100,
                                    color: primaryGreen,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: selectedBackgroundColor,
                              child: Icon(
                                Icons.park,
                                size: 100,
                                color: primaryGreen,
                              ),
                            ),
                    ),
                  ),
                  leading: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(40),
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_back,
                          color: darkGreen,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),

                // Main content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bibit name with responsive size
                        Text(
                          bibit.namaBibit,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Info section - using card for better visual grouping
                        Card(
                          elevation: 0,
                          color: backgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: shadowColor, width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow(
                                    Icons.tag,
                                    "Varietas: ${bibit.varietas}",
                                    smallTextSize),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                    Icons.height,
                                    "Tinggi: ${bibit.tinggi} cm",
                                    smallTextSize),
                                const SizedBox(height: 8),
                                _buildInfoRow(Icons.calendar_today,
                                    "Usia: ${bibit.usia} hari", smallTextSize),
                                const SizedBox(height: 8),
                                _buildInfoRow(Icons.check_circle,
                                    "Kondisi: ${bibit.kondisi}", smallTextSize,
                                    iconColor: primaryGreen),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Lokasi Tanam section
                        _buildSectionTitle("Lokasi Tanam", sectionTitleSize),
                        const SizedBox(height: 8),
                        Card(
                          elevation: 0,
                          color: backgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: shadowColor, width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow(Icons.place, "KPH: ${bibit.kph}",
                                    smallTextSize),
                                const SizedBox(height: 8),
                                _buildInfoRow(Icons.place_outlined,
                                    "BKPH: ${bibit.bkph}", smallTextSize),
                                const SizedBox(height: 8),
                                _buildInfoRow(Icons.map, "RKPH: ${bibit.rkph}",
                                    smallTextSize),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Catatan section
                        _buildSectionTitle("Catatan", sectionTitleSize),
                        const SizedBox(height: 8),
                        Card(
                          elevation: 0,
                          color: backgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: shadowColor, width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              bibit.catatan.isNotEmpty
                                  ? bibit.catatan
                                  : "Tidak ada catatan khusus.",
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: smallTextSize,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Produktivitas section
                        _buildSectionTitle("Produktivitas", sectionTitleSize),
                        const SizedBox(height: 8),
                        Card(
                          elevation: 0,
                          color: backgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: shadowColor, width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              bibit.produktivitas.isNotEmpty
                                  ? bibit.produktivitas
                                  : "Belum ada informasi produktivitas.",
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: smallTextSize,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // QR Code section
                        _buildSectionTitle("QR Code", sectionTitleSize),
                        const SizedBox(height: 16),
                        Center(
                          child: Card(
                            elevation: 0,
                            color: backgroundColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: shadowColor, width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  RepaintBoundary(
                                    key: qrKey,
                                    child: QrImageView(
                                      data: bibit.id,
                                      version: QrVersions.auto,
                                      size:
                                          screenWidth * 0.5, // Responsive size
                                      backgroundColor: Colors.white,
                                      errorStateBuilder: (cxt, err) {
                                        return Center(
                                          child: Text(
                                            "QR Error: $err",
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: screenWidth * 0.5,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _exportQR(bibit.id),
                                      icon: const Icon(Icons.download),
                                      label: const Text("Export QR"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryGreen,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Action buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: Icon(Icons.edit, color: primaryGreen),
                                  label: const Text("Edit"),
                                  onPressed: () {
                                    Get.toNamed(
                                      CetakBarcodeBibitPage.routeName,
                                      arguments: bibit,
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryGreen,
                                    side: BorderSide(color: primaryGreen),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  label: const Text("Hapus"),
                                  onPressed: () => _showDeleteConfirmation(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build consistent section titles
  Widget _buildSectionTitle(String title, double fontSize) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            color: darkGreen,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: primaryGreen.withOpacity(0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  // Helper method to build consistent info rows
  Widget _buildInfoRow(IconData icon, String text, double fontSize,
      {Color? iconColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor ?? inactiveColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // Improved delete confirmation dialog
  Future<void> _showDeleteConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Yakin ingin menghapus bibit ini?"),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Batal",
              style: TextStyle(color: inactiveColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final controller = Get.find<BibitController>();
        await controller.hapusBibitFromDatabase(bibit.id);
        Get.back();
        Get.snackbar(
          "Sukses",
          "Bibit berhasil dihapus.",
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: darkGreen,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
      } catch (e) {
        Get.snackbar(
          "Error",
          "Gagal menghapus bibit: $e",
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
      }
    }
  }

  // Improved QR export with error handling
  Future<void> _exportQR(String name) async {
    // Request proper permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.photos,
      Permission.storage,
    ].request();

    bool hasPermission = statuses[Permission.photos]!.isGranted ||
        statuses[Permission.storage]!.isGranted;

    if (!hasPermission) {
      Get.snackbar(
        "Akses Ditolak",
        "Tidak bisa menyimpan QR tanpa izin.",
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
      return;
    }

    try {
      // Show loading indicator
      final loadingOverlay = OverlayEntry(
        builder: (context) => Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: primaryGreen),
                    const SizedBox(height: 16),
                    const Text("Menyimpan QR Code..."),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(loadingOverlay);

      // Generate QR image
      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to generate image data");
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to temporary directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/qr_$name.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Save to gallery
      final result = await ImageGallerySaverPlus.saveFile(file.path);

      // Remove loading overlay
      loadingOverlay.remove();

      if (result['isSuccess'] == true) {
        Get.snackbar(
          "Sukses",
          "QR berhasil disimpan ke galeri.",
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: darkGreen,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
      } else {
        Get.snackbar(
          "Gagal",
          "QR tidak berhasil disimpan.",
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
      }
    } catch (e) {
      // Remove loading overlay if exists
      try {
        OverlayEntry? activeOverlay =
            ModalRoute.of(context)?.overlayEntries.lastOrNull;
        if (activeOverlay != null) {
          activeOverlay.remove();
        }
      } catch (_) {}

      Get.snackbar(
        "Error",
        "Gagal menyimpan QR: $e",
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    }
  }
}
