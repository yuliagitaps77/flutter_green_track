import 'package:flutter/material.dart';
import 'package:flutter_green_track/main.dart';
import 'package:flutter_green_track/fitur/authentication/LoginScreen.dart';
import 'package:get/get.dart';
import '../../controllers/dashboard_tpk/dashboard_tpk_controller.dart';
// Enum untuk role user
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

enum UserRole {
  adminPenyemaian,
  adminTPK,
}

// Base Dashboard Controller with common functionality
abstract class BaseDashboardController extends GetxController {
  var selectedIndex = 0.obs;

  void changeTab(int index) {
    selectedIndex.value = index;
  }
}

// Controller specific to Admin Penyemaian
class PenyemaianDashboardController extends BaseDashboardController {
  // Statistics for Penyemaian
  var totalBibit = 1245.obs;
  var bibitSiapTanam = 482.obs;
  var bibitButuhPerhatian = 23.obs;
  var pertumbuhanBibit = 15.obs;
  var bibitDipindai = 87.obs;

  // Additional methods specific to Penyemaian
  void refreshPenyemaianStats() {
    // Here you would call your API or data service to refresh stats
    // For now just simulate with dummy updates
    totalBibit.value = 1245 + (DateTime.now().second % 10);
    bibitSiapTanam.value = 482 + (DateTime.now().second % 5);
  }

  void cetakBarcode(int jumlah) {
    // Implementation for printing barcodes
    print('Mencetak $jumlah barcode bibit');
  }

  void updateBibitInfo(String id, Map<String, dynamic> data) {
    // Implementation for updating plant info
    print('Updating bibit info for ID: $id');
  }
}
