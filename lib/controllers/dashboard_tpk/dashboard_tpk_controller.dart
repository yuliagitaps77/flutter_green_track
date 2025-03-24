import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/dashboard_tpk_repository.dart';
import '../../data/models/dashboard_tpk_model.dart';

class TPKDashboardController extends GetxController {
  final DashboardTpkRepository repository = DashboardTpkRepository();

  RxBool isLoading = false.obs;
  RxList<DashboardTpkModel> items = <DashboardTpkModel>[].obs;

  // Tambahkan indeks item yang sedang dipilih/di-highlight
  RxInt selectedActionIndex = 0.obs;

  final RxList<Map<String, dynamic>> actions = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchItems();
    initActions();
  }

  void initActions() {
    actions.assignAll([
      {
        'icon': Icons.qr_code_scanner_rounded,
        'title': 'Scan\nBarcode',
        'onTap': () => handleAction(0),
        'highlight': true, // Default highlight first action
      },
      {
        'icon': Icons.inventory_2_rounded,
        'title': 'Inventory\nKayu',
        'onTap': () => handleAction(1),
        'highlight': false,
      },
      {
        'icon': Icons.history_rounded,
        'title': 'Riwayat\nScan',
        'onTap': () => handleAction(2),
        'highlight': false,
      },
      {
        'icon': Icons.calendar_month_rounded,
        'title': 'Jadwal\nPengiriman',
        'onTap': () => handleAction(3),
        'highlight': false,
      },
      {
        'icon': Icons.analytics_rounded,
        'title': 'Laporan\nTPK',
        'onTap': () => handleAction(4),
        'highlight': false,
      },
    ]);
  }

  // Metode untuk menangani klik pada action
  void handleAction(int index) {
    // Reset semua highlight
    for (var i = 0; i < actions.length; i++) {
      actions[i]['highlight'] = false;
    }

    // Set highlight untuk item yang diklik
    actions[index]['highlight'] = true;

    // Update selectedActionIndex
    selectedActionIndex.value = index;

    // Refresh list untuk memicu pembaruan UI
    actions.refresh();

    // Jalankan aksi sesuai dengan index
    switch (index) {
      case 0:
        handleScanBarcode();
        break;
      case 1:
        handleInventory();
        break;
      case 2:
        handleScanHistory();
        break;
      case 3:
        handleDeliverySchedule();
        break;
      case 4:
        handleReports();
        break;
    }
  }

  // Handler methods untuk masing-masing aksi
  void handleScanBarcode() {
    print('Handling scan barcode');
    // Implementasi scan barcode
  }

  void handleInventory() {
    print('Handling wood inventory');
    // Implementasi inventory kayu
  }

  void handleScanHistory() {
    print('Handling scan history');
    // Implementasi riwayat scan
  }

  void handleDeliverySchedule() {
    print('Handling delivery schedule');
    // Implementasi jadwal pengiriman
  }

  void handleReports() {
    print('Handling TPK reports');
    // Implementasi laporan TPK
  }

  Future<void> fetchItems() async {
    isLoading.value = true;
    try {
      final result = await repository.getAllDashboardTpk();
      items.assignAll(result);
    } catch (e) {
      print(e);
    } finally {
      isLoading.value = false;
    }
  }
}
