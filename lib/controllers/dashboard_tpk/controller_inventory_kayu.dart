import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/detail_bibit.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/tambah_persedian_kayu_page.dart';
import 'package:flutter_green_track/fitur/lacak_history/user_activity_model.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
    this.namaKayu = '',
    this.jenisKayu = '',
    this.batchPanen = '',
    this.imageUrl = '',
    this.jumlahStok = 0,
  });

  // Factory constructor to create from Firestore document
  factory InventoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Extract fields
    final jenis = data['jenis_kayu'] ?? '';
    final batchPanen = data['batch_panen'] ?? '';
    final namaKayu = data['nama_kayu'] ?? '';

    // Make sure jumlahStok is correctly extracted as an integer
    final jumlahStok = data['jumlah_stok'] is int
        ? data['jumlah_stok']
        : (int.tryParse(data['jumlah_stok']?.toString() ?? '0') ?? 0);

    print('🔥 [INVENTORY ITEM] Creating item with jumlahStok: $jumlahStok');

    // Format batch display name
    final batch = '$jenis - Batch $batchPanen';

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
      jenisKayu: jenis,
      batchPanen: batchPanen,
      imageUrl: imageUrl,
      jumlahStok: jumlahStok, // Make sure this is correctly passed
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

  @override
  void onInit() {
    super.onInit();
    fetchInventoryFromFirestore();
  }

  Future<void> fetchInventoryFromFirestore() async {
    print('🔥 [FIRESTORE FETCH] Starting to fetch inventory data...');
    isLoading.value = true;
    errorMessage.value = '';

    try {
      print('🔥 [FIRESTORE FETCH] Getting current user ID...');
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;

      if (userId == null) {
        print('❌ [FIRESTORE FETCH] No user logged in');
        errorMessage.value = 'Anda harus login terlebih dahulu';
        return;
      }
      print('🔥 [FIRESTORE FETCH] User ID: $userId');

      print('🔥 [FIRESTORE FETCH] Querying Firestore collection "kayu"...');
      final snapshot = await _firestore
          .collection('kayu')
          .where('id_user', isEqualTo: userId)
          .get()
          .timeout(const Duration(seconds: 15));

      print(
          '✅ [FIRESTORE FETCH] Query successful. Documents count: ${snapshot.docs.length}');

      // Clear existing items
      inventoryItems.clear();

      // Process documents
      if (snapshot.docs.isEmpty) {
        print('⚠️ [FIRESTORE FETCH] No documents found for this user');
      } else {
        int runningTotal = 0; // For debugging

        for (var doc in snapshot.docs) {
          print('🔥 [FIRESTORE FETCH] Processing document: ${doc.id}');
          try {
            final data = doc.data();

            // Extract jumlahStok directly from Firestore document
            final jumlahStok = data['jumlah_stok'] ?? 0;
            print(
                '🔥 [FIRESTORE FETCH] Document ${doc.id} has jumlahStok: $jumlahStok');

            runningTotal += (jumlahStok as num).toInt();

            final item = InventoryItem.fromFirestore(doc);
            inventoryItems.add(item);
            print(
                '✅ [FIRESTORE FETCH] Added item: ${item.batch} (${item.stock}) with stok: ${item.jumlahStok}');
          } catch (e) {
            print(
                '❌ [FIRESTORE FETCH] Error processing document ${doc.id}: $e');
          }
        }

        print(
            '🔥 [FIRESTORE FETCH] Running total from all documents: $runningTotal');
      }

      // Update counts
      updateCounts();
      print('✅ [FIRESTORE FETCH] Fetch completed successfully');
    } catch (e, stackTrace) {
      print('❌ [FIRESTORE FETCH] Error fetching inventory: $e');
      print('❌ [FIRESTORE FETCH] Stack trace: $stackTrace');
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
                  decoration: const InputDecoration(labelText: 'Nama Kayu'),
                  controller: namaController,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(labelText: 'Jenis Kayu'),
                  controller: jenisController,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(labelText: 'Batch Panen'),
                  controller: batchController,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(labelText: 'Jumlah Stok'),
                  controller: stokController,
                  keyboardType: TextInputType.number,
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
                          AppController.to.recordActivity(
                            activityType: ActivityTypes.deleteKayu,
                            name: "${item.namaKayu} | ${item.jenisKayu}",
                          );
                          // Close dialog first
                          Get.back();

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

                          // Remove from local list
                          inventoryItems.removeAt(index);
                          updateCounts();

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
                    : const Text('Hapus'),
              )),
        ],
      ),
    );
  }
// Tambahkan fungsi berikut ke dalam InventoryKayuController

  // Mengambil data kayu berdasarkan ID

  // Fungsi untuk navigasi ke halaman detail setelah scan berhasil
  // Tambahkan fungsi berikut ke dalam InventoryKayuController

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
      Get.dialog(
        Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
          ),
        ),
        barrierDismissible: false,
      );

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

                      // Location info
                      _buildInfoSection('Informasi Lokasi', [
                        _buildInfoRow('KPH', lokasi['kph']?.toString() ?? '-'),
                        _buildInfoRow(
                            'BKPH', lokasi['bkph']?.toString() ?? '-'),
                        _buildInfoRow(
                            'RKPH', lokasi['rkph']?.toString() ?? '-'),
                        _buildInfoRow('Luas Petak',
                            lokasi['luas_petak']?.toString() ?? '-'),
                        _buildInfoRow(
                            'Alamat', lokasi['alamat']?.toString() ?? '-'),
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
                                child: const Text('Hapus'),
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

                      // Location info
                      _buildInfoSection('Informasi Lokasi', [
                        _buildInfoRow('KPH', lokasi['kph']?.toString() ?? '-'),
                        _buildInfoRow(
                            'BKPH', lokasi['bkph']?.toString() ?? '-'),
                        _buildInfoRow(
                            'RKPH', lokasi['rkph']?.toString() ?? '-'),
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

                      // Location info
                      _buildInfoSection('Informasi Lokasi', [
                        _buildInfoRow('KPH', lokasi['kph']?.toString() ?? '-'),
                        _buildInfoRow(
                            'BKPH', lokasi['bkph']?.toString() ?? '-'),
                        _buildInfoRow(
                            'RKPH', lokasi['rkph']?.toString() ?? '-'),
                        _buildInfoRow('Luas Petak',
                            lokasi['luas_petak']?.toString() ?? '-'),
                        _buildInfoRow(
                            'Alamat', lokasi['alamat']?.toString() ?? '-'),
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

                // Action buttons
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Get.back();
                        editItem(index);
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
                        deleteItem(index);
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

  // Helper widgets for detail view
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
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
