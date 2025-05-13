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
import 'package:torch_light/torch_light.dart';
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

  // Add RxBool for flashlight state
  final RxBool isFlashlightOn = false.obs;

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
    // Turn off flashlight when controller is disposed
    if (isFlashlightOn.value) {
      TorchLight.disableTorch();
      isFlashlightOn.value = false;
    }
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
                color: Color(0xFFF5F9F5),
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close),
                    color: Color(0xFF424242),
                  ),
                ],
              ),
            ),

            // Camera preview placeholder
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
                      GestureDetector(
                        onTap: scanBarcode,
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
                        "Arahkan kamera ke barcode " +
                            (userRole == UserRole.adminPenyemaian
                                ? "Bibit"
                                : "Pohon"),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Tekan area scan untuk memulai",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Manual input option
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF4CAF50)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => showManualInputDialog(userRole),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  color: Color(0xFF4CAF50),
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "Input Manual",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4CAF50),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isFlashlightOn.value
                            ? Color(0xFF2E7D32)
                            : Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _toggleFlashlight,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isFlashlightOn.value
                                      ? Icons.flashlight_off_rounded
                                      : Icons.flashlight_on_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Obx(() => Text(
                                      isFlashlightOn.value
                                          ? "Matikan Flash"
                                          : "Nyalakan Flash",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),
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

  Future<void> scanBarcode() async {
    try {
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
        Get.back(result: result.rawContent);

        Get.snackbar(
          'Hasil Scan',
          'Kode barcode: ${result.rawContent}',
          backgroundColor: Color(0xFF4CAF50),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 15,
          margin: const EdgeInsets.all(10),
        );

        if (isAdminTPK) {
          print('🔥 [SCAN] Admin TPK: Navigasi ke detail kayu');
          final kayuController = Get.find<InventoryKayuController>();
          kayuController.navigateToDetailAfterScan(result.rawContent, userRole);
        } else if (isAdminPenyemaian) {
          print('🔥 [SCAN] Admin Penyemaian: Navigasi ke detail bibit');
          final bibitController = Get.find<BibitController>();
          bibitController.navigateToDetailAfterScan(result.rawContent);
        } else {
          print('⚠️ [SCAN] User role tidak teridentifikasi: ${userRole}');
          Get.snackbar(
            'Perhatian',
            'Peran pengguna tidak teridentifikasi',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            borderRadius: 15,
            margin: const EdgeInsets.all(10),
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
          borderRadius: 15,
          margin: const EdgeInsets.all(10),
        );
        showManualInputDialog(userRole);
      } else {
        Get.snackbar(
          'Error',
          'Error saat memindai: ${e.message}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 15,
          margin: const EdgeInsets.all(10),
        );
        showManualInputDialog(userRole);
      }
    } on Exception catch (e) {
      Get.snackbar(
        'Error',
        'Error tidak diketahui: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 15,
        margin: const EdgeInsets.all(10),
      );
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
    final Color buttonColor = Color(0xFF4CAF50); // Updated to primary green
    final Color textColor = Color(0xFF2E7D32); // Updated to dark green

    Get.dialog(
      AlertDialog(
        title: Text(
          dialogTitle,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: TextField(
          controller: codeController,
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: TextStyle(
              color: textColor,
              fontFamily: 'Poppins',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: buttonColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: buttonColor, width: 2),
            ),
            hintText: isAdminTPK ? 'Masukkan ID kayu' : 'Masukkan kode bibit',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'Poppins',
            ),
          ),
          keyboardType: TextInputType.text,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Batal',
              style: TextStyle(
                color: textColor,
                fontFamily: 'Poppins',
              ),
            ),
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
                  borderRadius: 15,
                  margin: const EdgeInsets.all(10),
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
                    borderRadius: 15,
                    margin: const EdgeInsets.all(10),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
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

  // Toggle flashlight function
  Future<void> _toggleFlashlight() async {
    try {
      if (isFlashlightOn.value) {
        await TorchLight.disableTorch();
        isFlashlightOn.value = false;
        Get.snackbar(
          'Flashlight',
          'Flash dimatikan',
          backgroundColor: Color(0xFF2E7D32),
          colorText: Colors.white,
          duration: Duration(seconds: 1),
          borderRadius: 15,
          margin: const EdgeInsets.all(10),
        );
      } else {
        final bool isAvailable = await TorchLight.isTorchAvailable();
        if (isAvailable) {
          await TorchLight.enableTorch();
          isFlashlightOn.value = true;
          Get.snackbar(
            'Flashlight',
            'Flash dinyalakan',
            backgroundColor: Color(0xFF4CAF50),
            colorText: Colors.white,
            duration: Duration(seconds: 1),
            borderRadius: 15,
            margin: const EdgeInsets.all(10),
          );
        } else {
          Get.snackbar(
            'Flashlight',
            'Perangkat tidak memiliki flash',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            borderRadius: 15,
            margin: const EdgeInsets.all(10),
          );
        }
      }
    } on Exception catch (e) {
      isFlashlightOn.value = false;
      Get.snackbar(
        'Error',
        'Tidak dapat mengakses flash: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 15,
        margin: const EdgeInsets.all(10),
      );
    }
  }
}
