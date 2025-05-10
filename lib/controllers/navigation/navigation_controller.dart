import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';
import 'package:flutter_green_track/controllers/dashboard_tpk/controller_inventory_kayu.dart';
import 'package:flutter_green_track/data/models/user_model.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/dashboard_tpk_page.dart';
import 'package:flutter_green_track/fitur/navigation/navigation_page.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/controller/controller_page_nav_bibit.dart';
import 'package:get/get.dart';
import '../../data/repositories/navigation_repository.dart';
import '../../data/models/navigation_model.dart';
import 'package:get/get.dart';

class NavigationController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // Current selected tab index
  var currentIndex = 0.obs;

  // User role to customize navigation options
  final UserRole userRole;

  // Animation controller for scan button effects
  late AnimationController _scanBtnAnimController;
  Animation<double>? _scanBtnAnimation;

  NavigationController({required this.userRole});

  @override
  void onInit() {
    super.onInit();

    // Initialize scan button animation controller
    _scanBtnAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void onClose() {
    _scanBtnAnimController.dispose();
    super.onClose();
  }

  // Change page and update current index
  void changePage(int index) {
    currentIndex.value = index;
  }

  // Navigate to scan page
  void goToScan() {
    // This could open a modal or navigate to a dedicated scan page
    // For now, we'll just update the index
    showScanBottomSheet();
    currentIndex.value = 0; // Index 2 is reserved for scan
  }

  // Show scan bottom sheet - can be called from anywhere in the app
  void showScanBottomSheet() {
    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    Get.bottomSheet(
      Container(
        height: Get.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar indicator
            Container(
              margin: EdgeInsets.only(top: 10),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 10),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Scan Barcode",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),

            // Camera preview placeholder (in real app, implement camera view)
            Expanded(
              child: Container(
                margin: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated scan indicator
                      GestureDetector(
                        onTap: scanBarcode, // Make entire area clickable
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: CustomPaint(
                            painter: ScannerPainter(
                              animation: _scanBtnAnimController,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Arahkan kamera ke barcode bibit",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Tekan area scan untuk memulai",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Manual input option
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showManualInputDialog(userRole),
                      icon: Icon(Icons.edit_rounded),
                      label: FittedBox(
                          child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text("Input Kode Manual"))),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF4CAF50),
                        side: BorderSide(color: Color(0xFF4CAF50)),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _toggleFlashlight,
                      icon: Icon(Icons.flashlight_on_rounded),
                      label: Text("Nyalakan Flash"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // Toggle flashlight function
  void _toggleFlashlight() {
    Get.snackbar(
      'Flashlight',
      'Flashlight function would be implemented here',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
    // In real implementation, would toggle device flashlight
  }

  Future<void> scanBarcode() async {
    try {
      // Cek user role terlebih dahulu
      print('🔥 [SCAN] User Role: ${userRole}');
      final bool isAdminTPK = userRole == UserRole.adminTPK;
      final bool isAdminPenyemaian = userRole == UserRole.adminPenyemaian;

      ScanOptions options = const ScanOptions(
        android: AndroidOptions(
          aspectTolerance: 0.5,
          useAutoFocus: true,
        ),
        restrictFormat: [BarcodeFormat.qr, BarcodeFormat.code128],
      );

      var result = await BarcodeScanner.scan(options: options);

      if (result.rawContent.isNotEmpty) {
        // Tutup bottom sheet jika ada
        Get.back(result: result.rawContent);

        // Tampilkan hasil scan dengan warna berbeda berdasarkan role
        Color bgColor = isAdminTPK ? Colors.brown : Colors.green;

        Get.snackbar(
          'Hasil Scan',
          'Kode barcode: ${result.rawContent}',
          backgroundColor: bgColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
        );

        // Penanganan hasil scan berdasarkan user role
        if (isAdminTPK) {
          // Admin TPK -> menangani kayu
          print('🔥 [SCAN] Admin TPK: Navigasi ke detail kayu');
          final kayuController = Get.find<InventoryKayuController>();
          kayuController.navigateToDetailAfterScan(result.rawContent, userRole);
        } else if (isAdminPenyemaian) {
          // Admin Penyemaian -> menangani bibit
          print('🔥 [SCAN] Admin Penyemaian: Navigasi ke detail bibit');
          final bibitController = Get.find<BibitController>();
          bibitController.navigateToDetailAfterScan(result.rawContent);
        } else {
          // Default jika role tidak teridentifikasi
          print('⚠️ [SCAN] User role tidak teridentifikasi: ${userRole}');
          Get.snackbar(
            'Perhatian',
            'Peran pengguna tidak teridentifikasi',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      }
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.cameraAccessDenied) {
        Get.snackbar(
          'Perhatian',
          'Izin kamera diperlukan untuk memindai barcode',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        // Tampilkan dialog input manual jika kamera tidak tersedia
        showManualInputDialog(userRole);
      } else {
        Get.snackbar(
          'Error',
          'Error saat memindai: ${e.message}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        // Tampilkan dialog input manual jika terjadi error pada scanner
        showManualInputDialog(userRole);
      }
    } on Exception catch (e) {
      Get.snackbar(
        'Error',
        'Error tidak diketahui: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      // Tampilkan dialog input manual jika terjadi error
      showManualInputDialog(userRole);
    }
  }

  void showManualInputDialog(UserRole userRole) {
    final TextEditingController codeController = TextEditingController();

    // Cek user role
    final bool isAdminTPK = userRole == UserRole.adminTPK;
    final bool isAdminPenyemaian = userRole == UserRole.adminPenyemaian;

    // Sesuaikan judul dialog berdasarkan role
    final String dialogTitle =
        isAdminTPK ? 'Input ID Kayu Manual' : 'Input Kode Bibit Manual';
    final String labelText = isAdminTPK ? 'ID Kayu' : 'Kode Bibit';
    final Color buttonColor = isAdminTPK ? Colors.brown : Colors.green;

    Get.dialog(
      AlertDialog(
        title: Text(dialogTitle),
        content: TextField(
          controller: codeController,
          decoration: InputDecoration(
            labelText: labelText,
            border: const OutlineInputBorder(),
            hintText: isAdminTPK ? 'Masukkan ID kayu' : 'Masukkan kode bibit',
          ),
          keyboardType: TextInputType.text,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.isNotEmpty) {
                Get.back();

                // Tampilkan hasil input manual
                Get.snackbar(
                  'Input Manual',
                  'Kode: ${codeController.text}',
                  backgroundColor: buttonColor,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                  snackPosition: SnackPosition.BOTTOM,
                );

                // Penanganan hasil input manual berdasarkan user role
                if (isAdminTPK) {
                  // Admin TPK -> menangani kayu
                  print('🔥 [MANUAL INPUT] Admin TPK: Navigasi ke detail kayu');
                  final kayuController = Get.find<InventoryKayuController>();
                  kayuController.navigateToDetailAfterScan(
                      codeController.text, userRole);
                } else if (isAdminPenyemaian) {
                  // Admin Penyemaian -> menangani bibit
                  print(
                      '🔥 [MANUAL INPUT] Admin Penyemaian: Navigasi ke detail bibit');
                  final bibitController = Get.find<BibitController>();
                  bibitController
                      .navigateToDetailAfterScan(codeController.text);
                } else {
                  // Default jika role tidak teridentifikasi
                  print(
                      '⚠️ [MANUAL INPUT] User role tidak teridentifikasi: ${userRole}');
                  Get.snackbar(
                    'Perhatian',
                    'Peran pengguna tidak teridentifikasi',
                    backgroundColor: Colors.orange,
                    colorText: Colors.white,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
            ),
            child: const Text('Cari'),
          ),
        ],
      ),
    );
  }

  // Custom navigation based on user role
  void navigateToInventory() {
    currentIndex.value = 1; // Index 1 is for Inventory/Bibit depending on role
  }

  void navigateToHistory() {
    currentIndex.value = 3; // Index 3 is for History
  }

  void navigateToStatistikInventoryTPK() {
    currentIndex.value = 3;
  }

  void navigateToAktivitasTPK() {
    currentIndex.value = 4;
  }

  void navigateToSettings() {
    currentIndex.value = 4; // Index 4 is for Settings
  }

  void navigateToDashboard() {
    currentIndex.value = 0; // Index 0 is for Dashboard
  }
}
