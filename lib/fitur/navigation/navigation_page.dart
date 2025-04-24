import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';
import 'package:flutter_green_track/data/models/user_model.dart';
import 'package:flutter_green_track/fitur/dashboard_penyemaian/admin_dashboard_penyemaian.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/admin_dashboard_tpk_page.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/dashboard_tpk_page.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/page_inventory_kayu.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/page/page_bibit/page_nav_bibit.dart';
import 'package:get/get.dart';
import '../../controllers/navigation/navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'dart:math' as math;

class MainNavigationContainer extends StatefulWidget {
  static String routeName = "/mainnavigation";
  late UserRole? userRole;

  MainNavigationContainer({
    Key? key,
    this.userRole,
  }) : super(key: key);

  @override
  _MainNavigationContainerState createState() =>
      _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer>
    with TickerProviderStateMixin {
  // Controller for navigation
  late NavigationController navigationController;

  // Controller for scan button animation
  late AnimationController _scanBtnAnimController;
  late Animation<double> _scanBtnScaleAnimation;
  late Animation<double> _scanBtnGlowAnimation;

  // Controller for page transitions
  late AnimationController _pageTransitionController;
  late Animation<double> _pageTransitionAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize controller with correct user role
    navigationController =
        Get.put(NavigationController(userRole: widget.userRole!));

    // Setup animations for scan button
    _scanBtnAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scanBtnScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(
      CurvedAnimation(
        parent: _scanBtnAnimController,
        curve: Curves.easeInOut,
      ),
    );

    _scanBtnGlowAnimation = Tween<double>(
      begin: 2.0,
      end: 6.0,
    ).animate(
      CurvedAnimation(
        parent: _scanBtnAnimController,
        curve: Curves.easeInOut,
      ),
    );

    // Setup animation for page transitions
    _pageTransitionController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _pageTransitionAnimation = CurvedAnimation(
      parent: _pageTransitionController,
      curve: Curves.easeInOut,
    );

    // Listen to page changes and update animation
    navigationController.currentIndex.listen((index) {
      _pageTransitionController.forward(from: 0.0);
    });
  }

  @override
  void dispose() {
    _scanBtnAnimController.dispose();
    _pageTransitionController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    try {
      ScanOptions options = const ScanOptions(
        android: AndroidOptions(
          aspectTolerance: 0.5,
          useAutoFocus: true,
        ),
        restrictFormat: [BarcodeFormat.qr, BarcodeFormat.code128],
      );

      var result = await BarcodeScanner.scan(options: options);

      if (result.rawContent.isNotEmpty) {
        // Tutup bottom sheet dan kembalikan hasil scan
        Get.back(result: result.rawContent);

        // Tampilkan hasil scan
        Get.snackbar(
          'Hasil Scan',
          'Kode barcode: ${result.rawContent}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
        );
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
      } else {
        Get.snackbar(
          'Error',
          'Error saat memindai: ${e.message}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on Exception catch (e) {
      Get.snackbar(
        'Error',
        'Error tidak diketahui: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showManualInputDialog() {
    final TextEditingController codeController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Input Kode Manual'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Kode Barcode',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
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
                Get.back(result: codeController.text);

                // Tampilkan hasil input manual
                Get.snackbar(
                  'Kode Manual',
                  'Kode: ${codeController.text}',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MediaQuery(
        // Memastikan ukuran responsif dengan mempertimbangkan densitas piksel
        data: MediaQuery.of(context).copyWith(
          textScaleFactor: 1.0, // Mengunci skala teks
        ),
        child: Stack(
          children: [
            // Main content
            _buildBody(),

            // Bottom navigation bar on top of content but behind the FAB
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildCustomBottomNavBar(),
            ),

            // Scan button on top of everything
            Positioned(
              bottom: 35, // Adjusted position to align with navigation bar
              left: 0,
              right: 0,
              child: Center(
                child: _buildScanButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom scan button
  Widget _buildScanButton() {
    // Responsive sizing based on screen width
    final double screenWidth = MediaQuery.of(context).size.width;
    final double buttonSize = screenWidth < 360 ? 58 : 62;

    return AnimatedBuilder(
      animation: _scanBtnAnimController,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => _handleScanPressed(),
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF43A047).withOpacity(0.4),
                  blurRadius: _scanBtnGlowAnimation.value,
                  spreadRadius: _scanBtnGlowAnimation.value / 2,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: Offset(0, 2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return Obx(() {
      final int index = navigationController.currentIndex.value;

      // Add bottom padding to the content to leave space for the navigation bar
      return Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.only(bottom: 80), // Space for bottom navigation
        child: Stack(
          children: [
            // Dashboard Screen
            AnimatedOpacity(
              opacity: index == 0 ? 1.0 : 0.0,
              duration: Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: index != 0,
                child: widget.userRole == UserRole.adminPenyemaian
                    ? PenyemaianDashboardScreen()
                    : TPKDashboardScreen(),
              ),
            ),

            // Inventory Screen
            AnimatedOpacity(
              opacity: index == 1 ? 1.0 : 0.0,
              duration: Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: index != 1,
                child: widget.userRole == UserRole.adminPenyemaian
                    ? DaftarBibitPage()
                    : _buildInventoryScreen(),
              ),
            ),

            // History Screen
            AnimatedOpacity(
              opacity: index == 3 ? 1.0 : 0.0,
              duration: Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: index != 3,
                child: _buildHistoryScreen(),
              ),
            ),

            // Settings Screen
            AnimatedOpacity(
              opacity: index == 4 ? 1.0 : 0.0,
              duration: Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: index != 4,
                child: _buildSettingsScreen(),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCustomBottomNavBar() {
    // Get labels based on user role with shorter text
    final List<String> labels = widget.userRole == UserRole.adminPenyemaian
        ? ['Beranda', 'Bibit', '', 'Riwayat', 'Aktivitas']
        : ['Beranda', 'Inventory Kayu', '', 'Riwayat', 'Aktivitas'];

    // Get icons based on user role
    final List<IconData> icons = widget.userRole == UserRole.adminPenyemaian
        ? [
            Icons.home_rounded,
            Icons.forest_rounded,
            Icons.qr_code_scanner_rounded,
            Icons.history_rounded,
            Icons.menu_rounded,
          ]
        : [
            Icons.home_rounded,
            Icons.inventory_2_rounded,
            Icons.qr_code_scanner_rounded,
            Icons.history_rounded,
            Icons.menu_rounded,
          ];

    // Responsive sizing based on screen width
    final double screenWidth = MediaQuery.of(context).size.width;
    final double navItemWidth =
        (screenWidth - 60) / 4; // Account for scan button gap
    final double iconSize = screenWidth < 360 ? 20 : 22;
    final double fontSize = screenWidth < 360 ? 10 : 11;

    return Container(
      height: 75, // Slightly reduced height
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          // Center notch for scan button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 70,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
              ),
            ),
          ),

          // Navigation items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              // Skip the middle button (scan) in the row
              if (index == 2) {
                return SizedBox(width: 60);
              }

              return Obx(() {
                final isSelected =
                    navigationController.currentIndex.value == index;

                return InkWell(
                  onTap: () => navigationController.changePage(index),
                  child: Container(
                    width: navItemWidth,
                    padding: EdgeInsets.symmetric(vertical: 5),
                    margin: EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(0xFF4CAF50).withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated icon with simplified animation
                        Icon(
                          icons[index],
                          color:
                              isSelected ? Color(0xFF2E7D32) : Colors.grey[600],
                          size: iconSize,
                        ),

                        const SizedBox(height: 4),

                        // Text label with FittedBox for responsive sizing
                        if (labels[index].isNotEmpty) // Skip empty labels
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              labels[index],
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Color(0xFF2E7D32)
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              });
            }),
          ),
        ],
      ),
    );
  }

  // Handle scan button press
  void _handleScanPressed() {
    // Provide haptic feedback if available
    HapticFeedback.mediumImpact();

    // Show scan UI
    _showScanBottomSheet();
  }

  // Show scan bottom sheet with camera access
  void _showScanBottomSheet() {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.9,
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
                        onTap: _scanBarcode, // Make entire area clickable
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
                      onPressed: _showManualInputDialog,
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

  // Placeholder for Inventory/Bibit screen
  Widget _buildInventoryScreen() {
    return Center(child: InventoryKayuPage());
  }

  void _toggleFlashlight() {
    Get.snackbar(
      'Flashlight',
      'Flashlight function would be implemented here',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
    // In real implementation, would toggle device flashlight
  }

  // Placeholder for History screen
  Widget _buildHistoryScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pageTransitionAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pageTransitionAnimation.value,
                child: FadeTransition(
                  opacity: _pageTransitionAnimation,
                  child: Icon(
                    Icons.history_rounded,
                    size: 100,
                    color: Color(0xFF4CAF50).withOpacity(0.5),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 20),
          AnimatedBuilder(
            animation: _pageTransitionAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - _pageTransitionAnimation.value)),
                child: Opacity(
                  opacity: _pageTransitionAnimation.value,
                  child: Text(
                    "Riwayat Scan",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 10),
          AnimatedBuilder(
            animation: _pageTransitionAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - _pageTransitionAnimation.value)),
                child: Opacity(
                  opacity: _pageTransitionAnimation.value,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Lihat riwayat pemindaian barcode yang telah dilakukan",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Placeholder for Settings screen
  Widget _buildSettingsScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pageTransitionAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: (1 - _pageTransitionAnimation.value) * math.pi / 10,
                child: Transform.scale(
                  scale: _pageTransitionAnimation.value,
                  child: FadeTransition(
                    opacity: _pageTransitionAnimation,
                    child: Icon(
                      Icons.settings_rounded,
                      size: 100,
                      color: Color(0xFF4CAF50).withOpacity(0.5),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 20),
          AnimatedBuilder(
            animation: _pageTransitionAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - _pageTransitionAnimation.value)),
                child: Opacity(
                  opacity: _pageTransitionAnimation.value,
                  child: Text(
                    "Pengaturan",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 10),
          AnimatedBuilder(
            animation: _pageTransitionAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - _pageTransitionAnimation.value)),
                child: Opacity(
                  opacity: _pageTransitionAnimation.value,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Konfigurasi aplikasi dan pengelolaan akun",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Custom scanner animation
class ScannerPainter extends CustomPainter {
  final Animation<double> animation;

  ScannerPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Draw scanner corners
    final cornerLength = width * 0.2;
    final cornerWidth = 3.0;
    final cornerRadius = 8.0;

    final paint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerWidth
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(cornerRadius, 0)
        ..lineTo(cornerLength, 0)
        ..moveTo(0, cornerRadius)
        ..lineTo(0, cornerLength),
      paint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(width - cornerLength, 0)
        ..lineTo(width - cornerRadius, 0)
        ..moveTo(width, cornerRadius)
        ..lineTo(width, cornerLength),
      paint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(width, height - cornerLength)
        ..lineTo(width, height - cornerRadius)
        ..moveTo(width - cornerLength, height)
        ..lineTo(width - cornerRadius, height),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, height - cornerLength)
        ..lineTo(0, height - cornerRadius)
        ..moveTo(cornerRadius, height)
        ..lineTo(cornerLength, height),
      paint,
    );

    // Draw scan line
    final scanLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF4CAF50).withOpacity(0),
          const Color(0xFF4CAF50).withOpacity(0.8),
          const Color(0xFF4CAF50).withOpacity(0),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, width, 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Animate the scan line
    final scanLineY = height * (0.2 + 0.6 * animation.value);
    canvas.drawLine(
      Offset(0, scanLineY),
      Offset(width, scanLineY),
      scanLinePaint,
    );

    // Draw pulsing circle in center
    final circlePaint = Paint()
      ..color = const Color(0xFF4CAF50).withOpacity(0.3 * (1 - animation.value))
      ..style = PaintingStyle.fill;

    final circleRadius = 20.0 + 10.0 * animation.value;
    canvas.drawCircle(
      Offset(width / 2, height / 2),
      circleRadius,
      circlePaint,
    );

    // Draw central target
    final targetPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      Offset(width / 2, height / 2),
      10,
      targetPaint,
    );

    // Draw cross in the center
    final crossPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(width / 2 - 5, height / 2),
      Offset(width / 2 + 5, height / 2),
      crossPaint,
    );

    canvas.drawLine(
      Offset(width / 2, height / 2 - 5),
      Offset(width / 2, height / 2 + 5),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ScannerPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
