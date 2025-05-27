import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/dashboard_tpk/dashboard_tpk_controller.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/detail_bibit.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/tambah_persedian_kayu_page.dart';
import 'package:flutter_green_track/fitur/lacak_history/user_activity_model.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../dashboard_pneyemaian/dashboard_penyemaian_controller.dart';

// PART 1: Enhanced InventoryItem class
class InventoryItem {
  final String id; // Firestore document ID
  final String batch;
  final String stock;
  final String namaKayu;
  final String jenisKayu;
  final String batchPanen;
  final String imageUrl; // First image URL from the list
  final int jumlahStok;

  InventoryItem({
    required this.id,
    required this.batch,
    required this.stock,
    required this.jumlahStok,
    this.namaKayu = '',
    this.jenisKayu = '',
    this.batchPanen = '',
    this.imageUrl = '',
  });

  // Factory constructor to create from Firestore document
  factory InventoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Extract fields with proper null handling
    final jenisKayu = data['jenis_kayu']?.toString() ?? '';
    final batchPanen = data['batch_panen']?.toString() ?? '';
    final namaKayu = data['nama_kayu']?.toString() ?? '';

    // Make sure jumlahStok is correctly extracted as an integer
    final jumlahStok = data['jumlah_stok'] is int
        ? data['jumlah_stok']
        : (int.tryParse(data['jumlah_stok']?.toString() ?? '0') ?? 0);

    print('🔥 [INVENTORY ITEM] Creating item with data:');
    print('🔥 [INVENTORY ITEM] Nama Kayu: $namaKayu');
    print('🔥 [INVENTORY ITEM] Jenis Kayu: $jenisKayu');
    print('🔥 [INVENTORY ITEM] Batch Panen: $batchPanen');
    print('🔥 [INVENTORY ITEM] Jumlah Stok: $jumlahStok');

    // Format batch display name
    final batch = '$jenisKayu - Batch $batchPanen';

    // Format stock display
    final stock = '$jumlahStok Unit';

    // Get first image URL if available
    final imageUrls = (data['gambar_image'] as List<dynamic>?) ?? [];
    final imageUrl = imageUrls.isNotEmpty ? imageUrls[0].toString() : '';

    return InventoryItem(
      id: doc.id,
      batch: batch,
      stock: stock,
      namaKayu: namaKayu,
      jenisKayu: jenisKayu,
      batchPanen: batchPanen,
      imageUrl: imageUrl,
      jumlahStok: jumlahStok,
    );
  }
}

// PART 2: Enhanced InventoryKayuController with full CRUD operations
class InventoryKayuController extends GetxController {
  var totalKayu = 0.obs;
  var jumlahBatch = 0.obs;
  var inventoryItems = <InventoryItem>[].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  // Add loading indicators for specific operations
  var isDeleting = false.obs;
  var isEditing = false.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _inventorySubscription;
  bool _isProcessingUpdate = false;

  @override
  void onInit() {
    super.onInit();
    // Initial fetch
    fetchInventoryFromFirestore();
    // Setup real-time listener after initial fetch
    setupRealtimeListener();
  }

  @override
  void onClose() {
    _inventorySubscription?.cancel();
    super.onClose();
  }

  void setupRealtimeListener() {
    print('🔄 [INVENTORY] Setting up real-time listener...');
    _inventorySubscription?.cancel();

    _inventorySubscription = _firestore
        .collection('kayu')
        .orderBy('created_at',
            descending: true) // Add ordering for better performance
        .limit(
            50) // Limit the number of documents to prevent performance issues
        .snapshots()
        .listen((snapshot) {
      if (_isProcessingUpdate) return; // Skip if already processing
      _isProcessingUpdate = true;

      print('📡 [INVENTORY] Received real-time update');
      _processInventorySnapshot(snapshot);

      _isProcessingUpdate = false;
    }, onError: (error) {
      print('❌ [INVENTORY] Error in real-time listener: $error');
      errorMessage.value = 'Error listening to updates: $error';
      _isProcessingUpdate = false;
    });
  }

  void _processInventorySnapshot(QuerySnapshot snapshot) {
    if (snapshot.docs.isEmpty) {
      print('⚠️ [INVENTORY] No documents found');
      inventoryItems.clear();
      updateCounts();
      return;
    }

    try {
      final newItems = <InventoryItem>[];
      int runningTotal = 0;

      for (var doc in snapshot.docs) {
        try {
          final item = InventoryItem.fromFirestore(doc);
          newItems.add(item);
          runningTotal += item.jumlahStok;
        } catch (e) {
          print('❌ [INVENTORY] Error processing document ${doc.id}: $e');
        }
      }

      // Update the list only if there are changes
      if (!_areListsEqual(inventoryItems, newItems)) {
        inventoryItems.value = newItems;
        totalKayu.value = runningTotal;
        jumlahBatch.value = newItems.length;
        print('✅ [INVENTORY] Updated list with ${newItems.length} items');
      }
    } catch (e) {
      print('❌ [INVENTORY] Error processing snapshot: $e');
      errorMessage.value = 'Error processing data: $e';
    }
  }

  bool _areListsEqual(List<InventoryItem> list1, List<InventoryItem> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id ||
          list1[i].jumlahStok != list2[i].jumlahStok) {
        return false;
      }
    }
    return true;
  }

  Future<void> fetchInventoryFromFirestore() async {
    print('🔄 [INVENTORY] Manually refreshing inventory...');
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final snapshot = await _firestore
          .collection('kayu')
          .orderBy('created_at', descending: true)
          .limit(50)
          .get()
          .timeout(const Duration(seconds: 15));

      _processInventorySnapshot(snapshot);
      print('✅ [INVENTORY] Manual refresh completed successfully');
    } catch (e) {
      print('❌ [INVENTORY] Error in manual refresh: $e');
      errorMessage.value = 'Gagal memuat data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void updateCounts() {
    print('🔄 [INVENTORY] Updating inventory counts...');

    // Update batch count - this is correct
    jumlahBatch.value = inventoryItems.length;
    print('🔄 [INVENTORY] Batch count: ${jumlahBatch.value}');

    // Fix for total kayu calculation
    int total = 0;
    for (var item in inventoryItems) {
      // Add the jumlahStok directly from each item
      total += item.jumlahStok;
    }

    print('🔄 [INVENTORY] Total kayu calculated: $total');
    totalKayu.value = total;
    print('🔄 [INVENTORY] Total kayu set to: ${totalKayu.value}');
  }

  void addNewInventory() {
    print('🔄 [INVENTORY] Navigating to add inventory page...');
    Get.toNamed(TambahPersediaanKayuPage.routeName);
  }

  Future<void> editItem(int index) async {
    print('🔄 [INVENTORY] Editing item at index: $index');
    final item = inventoryItems[index];

    // Set up controllers with current values
    final jenisController = TextEditingController(text: item.jenisKayu);
    final namaController = TextEditingController(text: item.namaKayu);
    final batchController = TextEditingController(text: item.batchPanen);
    final stokController =
        TextEditingController(text: item.jumlahStok.toString());

    // Ensure the text is set after controller initialization
    jenisController.text = item.jenisKayu;
    namaController.text = item.namaKayu;
    batchController.text = item.batchPanen;
    stokController.text = item.jumlahStok.toString();

    print('📝 [EDIT] Initialized controllers with values:');
    print('📝 [EDIT] Nama Kayu: ${namaController.text}');
    print('📝 [EDIT] Jenis Kayu: ${jenisController.text}');
    print('📝 [EDIT] Batch Panen: ${batchController.text}');
    print('📝 [EDIT] Jumlah Stok: ${stokController.text}');

    isEditing.value = true;

    try {
      // First, get the full document to have all fields
      print('🔥 [FIRESTORE EDIT] Fetching full document data: ${item.id}');
      final docSnapshot =
          await _firestore.collection('kayu').doc(item.id).get();

      if (!docSnapshot.exists) {
        print('❌ [FIRESTORE EDIT] Document not found');
        throw Exception('Data tidak ditemukan di database');
      }

      print('✅ [FIRESTORE EDIT] Document retrieved successfully');

      final currentData = docSnapshot.data() ?? {};

      // Show edit dialog
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              const Text('Edit Persediaan'),
              if (isEditing.value)
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  height: 15,
                  width: 15,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Optional: Display item image if available
                if (item.imageUrl.isNotEmpty)
                  Container(
                    height: 120,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(item.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Nama Kayu',
                    border: OutlineInputBorder(),
                  ),
                  controller: namaController,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Jenis Kayu',
                    border: OutlineInputBorder(),
                  ),
                  controller: jenisController,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Batch Panen',
                    border: OutlineInputBorder(),
                  ),
                  controller: batchController,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Stok',
                    border: OutlineInputBorder(),
                  ),
                  controller: stokController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Validate inputs
                  final jenisKayu = jenisController.text.trim();
                  final namaKayu = namaController.text.trim();
                  final batchPanen = batchController.text.trim();
                  final stokText = stokController.text.trim();

                  if (jenisKayu.isEmpty ||
                      namaKayu.isEmpty ||
                      batchPanen.isEmpty ||
                      stokText.isEmpty) {
                    Get.snackbar(
                      'Validasi',
                      'Semua field harus diisi',
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      colorText: Colors.orange,
                    );
                    return;
                  }

                  final jumlahStok = int.tryParse(stokText) ?? 0;
                  if (jumlahStok < 0) {
                    Get.snackbar(
                      'Validasi',
                      'Jumlah stok tidak valid',
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      colorText: Colors.orange,
                    );
                    return;
                  }

                  // Create updated batch name for display
                  final newBatch = '$jenisKayu - Batch $batchPanen';

                  // Close dialog first
                  Get.back();
                  isEditing.value = true;

                  print('🔥 [FIRESTORE EDIT] Updating document: ${item.id}');

                  // Update the document with the new values but keep the rest unchanged
                  final updates = {
                    'jenis_kayu': jenisKayu,
                    'nama_kayu': namaKayu,
                    'batch_panen': batchPanen,
                    'jumlah_stok': jumlahStok,
                    'updated_at': FieldValue.serverTimestamp(),
                  };

                  print('🔥 [FIRESTORE EDIT] Update data: $updates');

                  await _firestore
                      .collection('kayu')
                      .doc(item.id)
                      .update(updates);
                  print('✅ [FIRESTORE EDIT] Document updated successfully');
                  AppController.to.recordActivity(
                    activityType: ActivityTypes.updateKayu,
                    name: "${item.namaKayu} | ${item.jenisKayu}",
                  );
                  // Update local item immediately for UI responsiveness
                  inventoryItems[index] = InventoryItem(
                    id: item.id,
                    batch: newBatch,
                    stock: '$jumlahStok Unit',
                    namaKayu: namaKayu,
                    jenisKayu: jenisKayu,
                    batchPanen: batchPanen,
                    imageUrl: item.imageUrl, // Keep the same image
                    jumlahStok: jumlahStok,
                  );

                  updateCounts();

                  Get.snackbar(
                    'Sukses',
                    'Data berhasil diperbarui',
                    backgroundColor: Colors.green.withOpacity(0.1),
                    colorText: Colors.green,
                  );
                } catch (e, stackTrace) {
                  print('❌ [FIRESTORE EDIT] Error updating document: $e');
                  print('❌ [FIRESTORE EDIT] Stack trace: $stackTrace');

                  Get.snackbar(
                    'Error',
                    'Gagal memperbarui data: $e',
                    backgroundColor: Colors.red.withOpacity(0.1),
                    colorText: Colors.red,
                  );
                } finally {
                  isEditing.value = false;
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ [FIRESTORE EDIT] Error in edit process: $e');
      isEditing.value = false;

      Get.snackbar(
        'Error',
        'Gagal mengakses data: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  Future<void> deleteItem(int index) async {
    print('🔄 [INVENTORY] Deleting item at index: $index');
    final item = inventoryItems[index];

    Get.dialog(
      AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda yakin ingin menghapus item ini?'),
            const SizedBox(height: 16),

            // Show item details that will be deleted
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nama Kayu: ${item.namaKayu}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Jenis: ${item.jenisKayu}'),
                  Text('Batch: ${item.batchPanen}'),
                  Text('Stok: ${item.jumlahStok} Unit'),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Text(
              'Tindakan ini tidak dapat dibatalkan.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          Obx(() => ElevatedButton(
                onPressed: isDeleting.value
                    ? null // Disable button while deleting
                    : () async {
                        try {
                          // Set deleting state
                          isDeleting.value = true;

                          // Close dialog first
                          Get.back();

                          // Remove from local list immediately for better UX
                          inventoryItems.removeAt(index);
                          updateCounts();

                          // Record activity
                          AppController.to.recordActivity(
                            activityType: ActivityTypes.deleteKayu,
                            name: "${item.namaKayu} | ${item.jenisKayu}",
                          );

                          print(
                              '🔥 [FIRESTORE DELETE] Deleting document: ${item.id}');

                          // Delete from Firestore
                          await _firestore
                              .collection('kayu')
                              .doc(item.id)
                              .delete()
                              .timeout(const Duration(seconds: 10));

                          print(
                              '✅ [FIRESTORE DELETE] Document deleted successfully');

                          // Refresh dashboard data
                          try {
                            final dashboardController =
                                Get.find<TPKDashboardController>();
                            await dashboardController.refreshDashboardData();
                            print('✅ Dashboard data refreshed after deletion');
                          } catch (dashboardError) {
                            print(
                                '⚠️ Warning: Could not refresh dashboard: $dashboardError');
                          }

                          Get.snackbar(
                            'Sukses',
                            'Data berhasil dihapus',
                            backgroundColor: Colors.green.withOpacity(0.1),
                            colorText: Colors.green,
                          );
                        } catch (e, stackTrace) {
                          print(
                              '❌ [FIRESTORE DELETE] Error deleting document: $e');
                          print(
                              '❌ [FIRESTORE DELETE] Stack trace: $stackTrace');

                          // If there's an error, add the item back to the list
                          inventoryItems.insert(index, item);
                          updateCounts();

                          Get.snackbar(
                            'Error',
                            'Gagal menghapus data: $e',
                            backgroundColor: Colors.red.withOpacity(0.1),
                            colorText: Colors.white,
                          );
                        } finally {
                          isDeleting.value = false;
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.red.withOpacity(0.6),
                ),
                child: isDeleting.value
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Menghapus...'),
                        ],
                      )
                    : const Text(
                        'Hapus',
                        style: TextStyle(color: Colors.white),
                      ),
              )),
        ],
      ),
    );
  }

  // Mengambil data kayu berdasarkan ID
  Future<InventoryItem?> getKayuById(String kayuId) async {
    try {
      print('🔥 [GET KAYU] Mencari kayu dengan ID: $kayuId');
      isLoading.value = true;

      // Coba cari di cache terlebih dahulu
      final cachedItem =
          inventoryItems.firstWhereOrNull((item) => item.id == kayuId);

      if (cachedItem != null) {
        print('✅ [GET KAYU] Kayu ditemukan di cache: ${cachedItem.batch}');
        return cachedItem;
      }

      // Jika tidak ada di cache, cari di Firestore
      print(
          '🔥 [GET KAYU] Kayu tidak ditemukan di cache, mencari di Firestore');
      final snapshot = await _firestore
          .collection('kayu')
          .doc(kayuId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.exists) {
        print('✅ [GET KAYU] Kayu ditemukan di Firestore: ${snapshot.id}');
        final item = InventoryItem.fromFirestore(snapshot);
        return item;
      }

      print('⚠️ [GET KAYU] Kayu tidak ditemukan: $kayuId');
      return null;
    } catch (e) {
      print('❌ [GET KAYU] Error saat mencari kayu: $e');
      errorMessage.value = 'Gagal mendapatkan detail kayu';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Fungsi untuk navigasi ke halaman detail setelah scan berhasil
  void navigateToDetailAfterScan(
      String barcodeResult, UserRole? userRole) async {
    try {
      // Ambil data kayu dari Firestore
      final snapshot = await _firestore
          .collection('kayu')
          .doc(barcodeResult)
          .get()
          .timeout(const Duration(seconds: 10));

      Get.back(); // Tutup loading dialog

      if (snapshot.exists) {
        print('✅ [NAVIGATE DETAIL] Kayu ditemukan, navigasi ke halaman detail');
        AppController.to.recordActivity(
            activityType: ActivityTypes.scanPohon,
            name:
                "${snapshot.data()?['nama_kayu']} | ${snapshot.data()?['jenis_kayu']}",
            metadata: {
              "pohon": {
                "nama_kayu": snapshot.data()?['nama_kayu'],
                "jenis_kayu": snapshot.data()?['jenis_kayu'],
              },
              'updated_at': DateTime.now(),
              'timestamp': DateTime.now().toString(),
            });
        // Navigasi ke halaman detail
        Get.to(() => KayuDetailPage(
              kayuId: barcodeResult,
              userRole: userRole,
            ));
      } else {
        print('⚠️ [NAVIGATE DETAIL] Kayu tidak ditemukan: $barcodeResult');
        Get.snackbar(
          'Informasi',
          'Kayu dengan ID $barcodeResult tidak ditemukan',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.back(); // Tutup loading dialog jika terjadi error
      print('❌ [NAVIGATE DETAIL] Error saat navigasi: $e');
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Melihat detail kayu setelah scan (full access)
  void viewKayuDetailAfterScan(InventoryItem item) async {
    try {
      print('🔥 [FIRESTORE VIEW] Fetching full document data: ${item.id}');
      final docSnapshot =
          await _firestore.collection('kayu').doc(item.id).get();

      if (!docSnapshot.exists) {
        print('❌ [FIRESTORE VIEW] Document not found');
        throw Exception('Data tidak ditemukan di database');
      }

      print('✅ [FIRESTORE VIEW] Document retrieved successfully');
      final data = docSnapshot.data() ?? {};

      // Extract data
      final imageUrls = (data['gambar_image'] as List<dynamic>?) ?? [];
      final lokasi = data['lokasi_tanam'] as Map<String, dynamic>? ?? {};
      final tanggalLahir = data['tanggal_lahir_pohon'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              data['tanggal_lahir_pohon'] as int)
          : null;

      // Format dates for display
      final createdAt =
          data['created_at'] != null && data['created_at'] is Timestamp
              ? (data['created_at'] as Timestamp).toDate()
              : null;
      final updatedAt =
          data['updated_at'] != null && data['updated_at'] is Timestamp
              ? (data['updated_at'] as Timestamp).toDate()
              : null;

      final formatter = DateFormat('dd MMM yyyy, HH:mm');

      Get.dialog(
        Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: Get.height * 0.8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Inventory: ${item.namaKayu}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const Divider(),

                // Scrollable content
                Expanded(
                  child: ListView(
                    children: [
                      // Images carousel
                      if (imageUrls.isNotEmpty)
                        Container(
                          height: 200,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: PageView.builder(
                            itemCount: imageUrls.length,
                            itemBuilder: (context, imageIndex) {
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        imageUrls[imageIndex].toString()),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // Basic info
                      _buildInfoSection('Informasi Dasar', [
                        _buildInfoRow(
                            'ID Kayu', data['id_kayu']?.toString() ?? '-'),
                        _buildInfoRow(
                            'Barcode', data['barcode']?.toString() ?? '-'),
                        _buildInfoRow(
                            'Nama Kayu', data['nama_kayu']?.toString() ?? '-'),
                        _buildInfoRow('Jenis Kayu',
                            data['jenis_kayu']?.toString() ?? '-'),
                        _buildInfoRow(
                            'Varietas', data['varietas']?.toString() ?? '-'),
                        _buildInfoRow('Batch Panen',
                            data['batch_panen']?.toString() ?? '-'),
                        _buildInfoRow(
                            'Jumlah Stok', '${data['jumlah_stok'] ?? 0} Unit'),
                      ]),

                      // Physical attributes
                      _buildInfoSection('Karakteristik Fisik', [
                        _buildInfoRow('Usia', '${data['usia'] ?? 0} tahun'),
                        _buildInfoRow('Tinggi', '${data['tinggi'] ?? 0} meter'),
                        if (tanggalLahir != null)
                          _buildInfoRow('Tanggal Lahir Pohon',
                              DateFormat('dd MMM yyyy').format(tanggalLahir)),
                      ]),

                      // Additional info
                      _buildInfoSection('Informasi Tambahan', [
                        _buildInfoRow(
                            'Catatan', data['catatan']?.toString() ?? '-'),
                        if (createdAt != null)
                          _buildInfoRow(
                              'Tanggal Dibuat', formatter.format(createdAt)),
                        if (updatedAt != null)
                          _buildInfoRow('Terakhir Diperbarui',
                              formatter.format(updatedAt)),
                      ]),
                    ],
                  ),
                ),

                // Action buttons - untuk admin TPK, bisa edit dan hapus
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Get.back();
                        // Cari index item di inventoryItems
                        final index = inventoryItems
                            .indexWhere((element) => element.id == item.id);
                        if (index != -1) {
                          editItem(index);
                        } else {
                          Get.snackbar(
                            'Peringatan',
                            'Item tidak ditemukan dalam daftar',
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                          );
                        }
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        // Tampilkan dialog konfirmasi hapus
                        Get.dialog(
                          AlertDialog(
                            title: const Text('Konfirmasi'),
                            content: Text(
                                'Apakah Anda yakin ingin menghapus ${item.namaKayu}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Get.back();
                                  // Cari index item di inventoryItems
                                  final index = inventoryItems.indexWhere(
                                      (element) => element.id == item.id);
                                  if (index != -1) {
                                    deleteItem(index);
                                  } else {
                                    Get.snackbar(
                                      'Peringatan',
                                      'Item tidak ditemukan dalam daftar',
                                      backgroundColor: Colors.orange,
                                      colorText: Colors.white,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Hapus'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('❌ [FIRESTORE VIEW] Error viewing document details: $e');

      Get.snackbar(
        'Error',
        'Gagal mengakses detail data: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  // Melihat detail kayu setelah scan (limited access untuk admin penyemaian)
  void viewKayuDetailLimitedAfterScan(InventoryItem item) async {
    try {
      print('🔥 [FIRESTORE VIEW] Fetching limited document data: ${item.id}');
      final docSnapshot =
          await _firestore.collection('kayu').doc(item.id).get();

      if (!docSnapshot.exists) {
        print('❌ [FIRESTORE VIEW] Document not found');
        throw Exception('Data tidak ditemukan di database');
      }

      print('✅ [FIRESTORE VIEW] Document retrieved successfully');
      final data = docSnapshot.data() ?? {};

      // Extract data
      final imageUrls = (data['gambar_image'] as List<dynamic>?) ?? [];
      final lokasi = data['lokasi_tanam'] as Map<String, dynamic>? ?? {};

      // Format dates for display
      final createdAt =
          data['created_at'] != null && data['created_at'] is Timestamp
              ? (data['created_at'] as Timestamp).toDate()
              : null;

      final formatter = DateFormat('dd MMM yyyy, HH:mm');

      Get.dialog(
        Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: Get.height * 0.8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Inventory: ${item.namaKayu}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Hanya Lihat',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const Divider(),

                // Scrollable content
                Expanded(
                  child: ListView(
                    children: [
                      // Images carousel
                      if (imageUrls.isNotEmpty)
                        Container(
                          height: 200,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: PageView.builder(
                            itemCount: imageUrls.length,
                            itemBuilder: (context, imageIndex) {
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        imageUrls[imageIndex].toString()),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // Basic info - hanya informasi dasar
                      _buildInfoSection('Informasi Dasar', [
                        _buildInfoRow(
                            'Nama Kayu', data['nama_kayu']?.toString() ?? '-'),
                        _buildInfoRow('Jenis Kayu',
                            data['jenis_kayu']?.toString() ?? '-'),
                        _buildInfoRow('Batch Panen',
                            data['batch_panen']?.toString() ?? '-'),
                        _buildInfoRow(
                            'Jumlah Stok', '${data['jumlah_stok'] ?? 0} Unit'),
                      ]),

                      // Additional info - hanya sebagian
                      if (createdAt != null)
                        _buildInfoSection('Informasi Tambahan', [
                          _buildInfoRow(
                              'Tanggal Dibuat', formatter.format(createdAt)),
                        ]),
                    ],
                  ),
                ),

                // Tanpa action buttons untuk admin penyemaian
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('❌ [FIRESTORE VIEW] Error viewing document details: $e');

      Get.snackbar(
        'Error',
        'Gagal mengakses detail data: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  Future<void> viewItemDetails(int index) async {
    final item = inventoryItems[index];

    try {
      print('🔥 [FIRESTORE VIEW] Fetching full document data: ${item.id}');
      final docSnapshot =
          await _firestore.collection('kayu').doc(item.id).get();

      if (!docSnapshot.exists) {
        print('❌ [FIRESTORE VIEW] Document not found');
        throw Exception('Data tidak ditemukan di database');
      }

      print('✅ [FIRESTORE VIEW] Document retrieved successfully');
      final data = docSnapshot.data() ?? {};

      // Extract data
      final imageUrls = (data['gambar_image'] as List<dynamic>?) ?? [];
      final lokasi = data['lokasi_tanam'] as Map<String, dynamic>? ?? {};
      final tanggalLahir = data['tanggal_lahir_pohon'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              data['tanggal_lahir_pohon'] as int)
          : null;

      // Format dates for display
      final createdAt =
          data['created_at'] != null && data['created_at'] is Timestamp
              ? (data['created_at'] as Timestamp).toDate()
              : null;
      final updatedAt =
          data['updated_at'] != null && data['updated_at'] is Timestamp
              ? (data['updated_at'] as Timestamp).toDate()
              : null;

      final formatter = DateFormat('dd MMM yyyy, HH:mm');

      Get.dialog(
        Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: Get.width * 0.9,
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: Get.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and close button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Detail Inventory: ${item.namaKayu}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Images carousel
                        if (imageUrls.isNotEmpty)
                          Container(
                            height: 250,
                            margin: const EdgeInsets.only(bottom: 24),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: PageView.builder(
                                itemCount: imageUrls.length,
                                itemBuilder: (context, imageIndex) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        imageUrls[imageIndex].toString(),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: Color(0xFFE8F5E9),
                                            child: Icon(
                                              Icons.image_not_supported,
                                              size: 50,
                                              color: Color(0xFF4CAF50),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                        // Basic info
                        _buildInfoSection(
                          'Informasi Dasar',
                          [
                            _buildInfoRow(
                                'ID Kayu', data['id_kayu']?.toString() ?? '-'),
                            _buildInfoRow(
                                'Barcode', data['barcode']?.toString() ?? '-'),
                            _buildInfoRow('Nama Kayu',
                                data['nama_kayu']?.toString() ?? '-'),
                            _buildInfoRow('Jenis Kayu',
                                data['jenis_kayu']?.toString() ?? '-'),
                            _buildInfoRow('Varietas',
                                data['varietas']?.toString() ?? '-'),
                            _buildInfoRow('Batch Panen',
                                data['batch_panen']?.toString() ?? '-'),
                            _buildInfoRow('Jumlah Stok',
                                '${data['jumlah_stok'] ?? 0} Unit'),
                          ],
                          icon: Icons.info_outline,
                        ),

                        // Physical attributes
                        _buildInfoSection(
                          'Karakteristik Fisik',
                          [
                            _buildInfoRow('Usia', '${data['usia'] ?? 0} tahun'),
                            _buildInfoRow(
                                'Tinggi', '${data['tinggi'] ?? 0} meter'),
                            if (tanggalLahir != null)
                              _buildInfoRow(
                                  'Tanggal Lahir Pohon',
                                  DateFormat('dd MMM yyyy')
                                      .format(tanggalLahir)),
                          ],
                          icon: Icons.straighten,
                        ),

                        // Location info

                        // Additional info
                        _buildInfoSection(
                          'Informasi Tambahan',
                          [
                            _buildInfoRow(
                                'Catatan', data['catatan']?.toString() ?? '-'),
                            if (createdAt != null)
                              _buildInfoRow('Tanggal Dibuat',
                                  formatter.format(createdAt)),
                            if (updatedAt != null)
                              _buildInfoRow('Terakhir Diperbarui',
                                  formatter.format(updatedAt)),
                          ],
                          icon: Icons.notes,
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Get.back();
                          editItem(index);
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFF4CAF50),
                          side: BorderSide(color: Color(0xFF4CAF50)),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          deleteItem(index);
                        },
                        icon: const Icon(
                          Icons.delete,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Hapus',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: true,
      );
    } catch (e) {
      print('❌ [FIRESTORE VIEW] Error viewing document details: $e');
      Get.snackbar(
        'Error',
        'Gagal mengakses detail data: $e',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
        borderRadius: 8,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
        icon: Icon(Icons.error_outline, color: Colors.red.shade700),
      );
    }
  }

  // Helper widgets for detail view
  Widget _buildInfoSection(String title, List<Widget> children,
      {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: Color(0xFF4CAF50)),
                SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF424242),
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void refreshInventory() {
    print('🔄 [INVENTORY] Manually refreshing inventory...');
    fetchInventoryFromFirestore();
  }
}
