import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';
import 'package:flutter_green_track/controllers/dashboard_tpk/controller_inventory_kayu.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class KayuDetailPage extends StatefulWidget {
  final String kayuId;
  final UserRole? userRole;

  const KayuDetailPage({
    Key? key,
    required this.kayuId,
    this.userRole,
  }) : super(key: key);

  @override
  _KayuDetailPageState createState() => _KayuDetailPageState();
}

class _KayuDetailPageState extends State<KayuDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InventoryKayuController kayuController =
      Get.find<InventoryKayuController>();

  bool isLoading = true;
  Map<String, dynamic> kayuData = {};
  List<dynamic> imageUrls = [];
  Map<String, dynamic> lokasiData = {};

  // Colors
  final Color primaryBrown = Color(0xFF8B4513);
  final Color secondaryBrown = Color(0xFFCD853F);
  final Color accentColor = Color(0xFFD2B48C);

  @override
  void initState() {
    super.initState();
    _fetchKayuData();
  }

  Future<void> _fetchKayuData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final docSnapshot =
          await _firestore.collection('kayu').doc(widget.kayuId).get();

      if (!docSnapshot.exists) {
        Get.snackbar(
          'Error',
          'Data kayu tidak ditemukan',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Get.back();
        return;
      }

      setState(() {
        kayuData = docSnapshot.data() ?? {};
        imageUrls = (kayuData['gambar_image'] as List<dynamic>?) ?? [];
        lokasiData = (kayuData['lokasi_tanam'] as Map<String, dynamic>?) ?? {};
        isLoading = false;
      });
    } catch (e) {
      print('❌ [DETAIL PAGE] Error fetching kayu data: $e');
      Get.snackbar(
        'Error',
        'Gagal memuat data kayu: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdminTPK = widget.userRole == UserRole.adminTPK;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Kayu'),
        backgroundColor: primaryBrown,
        elevation: 0,
        actions: isAdminTPK
            ? [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _showEditDialog();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _showDeleteConfirmation();
                  },
                ),
              ]
            : null,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBrown)))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Carousel
                  _buildImageCarousel(),

                  // Info Sections
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Info
                        _buildMainInfo(),

                        SizedBox(height: 24),

                        // QR Code Section
                        _buildQrCodeSection(screenWidth),

                        SizedBox(height: 24),

                        // Tabs for additional info
                        _buildInfoTabs(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: isAdminTPK
          ? FloatingActionButton.extended(
              onPressed: () {
                _showStockAdjustmentDialog();
              },
              label: Text('Ubah Stok'),
              icon: Icon(Icons.edit_note),
              backgroundColor: primaryBrown,
            )
          : null,
    );
  }

  Widget _buildImageCarousel() {
    if (imageUrls.isEmpty) {
      return Container(
        height: 250,
        width: double.infinity,
        color: Colors.grey[200],
        child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
      );
    }

    return Container(
      height: 250,
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Image.network(
            imageUrls[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                  child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: AlwaysStoppedAnimation<Color>(primaryBrown),
              ));
            },
          );
        },
      ),
    );
  }

  Widget _buildMainInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kayuData['nama_kayu'] ?? 'Tidak ada nama',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryBrown,
              ),
            ),
            SizedBox(height: 8),
            Text(
              kayuData['jenis_kayu'] ?? 'Jenis tidak tersedia',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow(
                'Batch Panen', kayuData['batch_panen']?.toString() ?? '-'),
            _buildInfoRow(
                'Jumlah Stok', '${kayuData['jumlah_stok'] ?? 0} Unit'),
            _buildInfoRow('Varietas', kayuData['varietas']?.toString() ?? '-'),
            if (kayuData['created_at'] != null &&
                kayuData['created_at'] is Timestamp)
              _buildInfoRow(
                  'Tanggal Dibuat',
                  DateFormat('dd MMM yyyy')
                      .format((kayuData['created_at'] as Timestamp).toDate())),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCodeSection(double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Decorative wood icon
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.forest,
              color: primaryBrown,
              size: 36,
            ),
          ),

          SizedBox(height: 20),

          // QR Container with inner shadow and border
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: secondaryBrown.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: QrImageView(
              data: widget.kayuId,
              version: QrVersions.auto,
              size: screenWidth * 0.5,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: primaryBrown,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: primaryBrown,
              ),
              errorStateBuilder: (cxt, err) {
                return Center(
                  child: Text(
                    "QR Error: $err",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 20),

          // Kayu ID with decorative elements
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: secondaryBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: secondaryBrown.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.qr_code,
                  size: 16,
                  color: primaryBrown,
                ),
                SizedBox(width: 8),
                Text(
                  widget.kayuId,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 10),

          // Caption text
          Text(
            "Scan to track wood inventory",
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTabs() {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(50),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: primaryBrown,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black54,
              tabs: [
                Tab(text: 'Fisik'),
                Tab(text: 'Lokasi'),
                Tab(text: 'Lainnya'),
              ],
            ),
          ),
          Container(
            height: 250,
            margin: EdgeInsets.only(top: 16),
            child: TabBarView(
              children: [
                // Physical attributes tab
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Karakteristik Fisik',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBrown)),
                          Divider(),
                          _buildInfoRow(
                              'Usia', '${kayuData['usia'] ?? 0} tahun'),
                          _buildInfoRow(
                              'Tinggi', '${kayuData['tinggi'] ?? 0} meter'),
                          if (kayuData['tanggal_lahir_pohon'] != null)
                            _buildInfoRow(
                                'Tanggal Lahir Pohon',
                                DateFormat('dd MMM yyyy').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        kayuData['tanggal_lahir_pohon']
                                            as int))),
                          _buildInfoRow('ID Kayu',
                              kayuData['id_kayu']?.toString() ?? '-'),
                          _buildInfoRow('Barcode',
                              kayuData['barcode']?.toString() ?? '-'),
                        ],
                      ),
                    ),
                  ),
                ),

                // Location tab
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Informasi Lokasi',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBrown)),
                          Divider(),
                          _buildInfoRow(
                              'KPH', lokasiData['kph']?.toString() ?? '-'),
                          _buildInfoRow(
                              'BKPH', lokasiData['bkph']?.toString() ?? '-'),
                          _buildInfoRow(
                              'RKPH', lokasiData['rkph']?.toString() ?? '-'),
                          _buildInfoRow('Luas Petak',
                              lokasiData['luas_petak']?.toString() ?? '-'),
                          _buildInfoRow('Alamat',
                              lokasiData['alamat']?.toString() ?? '-'),
                        ],
                      ),
                    ),
                  ),
                ),

                // Additional info tab
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Informasi Tambahan',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBrown)),
                          Divider(),
                          _buildInfoRow('Catatan',
                              kayuData['catatan']?.toString() ?? '-'),
                          if (kayuData['updated_at'] != null &&
                              kayuData['updated_at'] is Timestamp)
                            _buildInfoRow(
                                'Terakhir Diperbarui',
                                DateFormat('dd MMM yyyy, HH:mm').format(
                                    (kayuData['updated_at'] as Timestamp)
                                        .toDate())),
                          _buildInfoRow('ID User',
                              kayuData['id_user']?.toString() ?? '-'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    // Dapatkan indeks item di inventoryItems berdasarkan kayuId
    final index = kayuController.inventoryItems
        .indexWhere((item) => item.id == widget.kayuId);

    if (index != -1) {
      // Jika item ditemukan, panggil fungsi editItem dari controller
      kayuController.editItem(index).then((_) {
        // Setelah edit selesai, refresh data
        _fetchKayuData();
      });
    } else {
      // Jika item tidak ditemukan di list, tampilkan pesan error
      Get.snackbar(
        'Error',
        'Item tidak ditemukan dalam daftar inventaris',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      // Mungkin perlu refresh list
      kayuController.fetchInventoryFromFirestore().then((_) {
        _fetchKayuData();
      });
    }
  }

  void _showDeleteConfirmation() {
    // Dapatkan indeks item di inventoryItems berdasarkan kayuId
    final index = kayuController.inventoryItems
        .indexWhere((item) => item.id == widget.kayuId);

    if (index != -1) {
      // Jika item ditemukan, panggil fungsi deleteItem dari controller
      kayuController.deleteItem(index).then((_) {
        // Setelah hapus selesai, kembali ke halaman sebelumnya
        Get.back(); // Kembali ke halaman daftar inventaris
      });
    } else {
      // Jika item tidak ditemukan di list, coba hapus langsung dari database
      Get.dialog(
        AlertDialog(
          title: Text('Konfirmasi'),
          content: Text(
              'Apakah Anda yakin ingin menghapus ${kayuData['nama_kayu']}?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  Get.back(); // Tutup dialog

                  // Tampilkan loading
                  Get.dialog(
                    Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                      ),
                    ),
                    barrierDismissible: false,
                  );

                  // Hapus dokumen langsung dari Firestore
                  await _firestore
                      .collection('kayu')
                      .doc(widget.kayuId)
                      .delete();

                  Get.back(); // Tutup loading dialog
                  Get.back(); // Kembali ke halaman sebelumnya

                  Get.snackbar(
                    'Sukses',
                    'Data berhasil dihapus',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );

                  // Refresh inventoryItems
                  kayuController.fetchInventoryFromFirestore();
                } catch (e) {
                  Get.back(); // Tutup loading dialog

                  Get.snackbar(
                    'Error',
                    'Gagal menghapus data: $e',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Hapus'),
            ),
          ],
        ),
      );
    }
  }

  void _showStockAdjustmentDialog() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    bool isAddition = true;

    Get.dialog(
      StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text('Penyesuaian Stok'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Radio buttons for add/subtract
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text('Tambah'),
                      value: true,
                      groupValue: isAddition,
                      onChanged: (value) {
                        setState(() {
                          isAddition = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text('Kurang'),
                      value: false,
                      groupValue: isAddition,
                      onChanged: (value) {
                        setState(() {
                          isAddition = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Jumlah',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Catatan',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isNotEmpty) {
                  final amount = int.tryParse(amountController.text) ?? 0;
                  if (amount > 0) {
                    Get.back(); // Tutup dialog

                    try {
                      // Tampilkan loading
                      Get.dialog(
                        Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.brown),
                          ),
                        ),
                        barrierDismissible: false,
                      );

                      // Dapatkan data kayu saat ini
                      final docSnapshot = await _firestore
                          .collection('kayu')
                          .doc(widget.kayuId)
                          .get();
                      if (!docSnapshot.exists) {
                        throw Exception('Data kayu tidak ditemukan');
                      }

                      final data = docSnapshot.data() ?? {};
                      final currentStock = data['jumlah_stok'] is int
                          ? data['jumlah_stok']
                          : (int.tryParse(
                                  data['jumlah_stok']?.toString() ?? '0') ??
                              0);

                      // Hitung stok baru
                      int newStock = currentStock;
                      if (isAddition) {
                        newStock = currentStock + amount;
                      } else {
                        newStock = currentStock - amount;
                        if (newStock < 0)
                          newStock = 0; // Prevent negative stock
                      }

                      // Update stok di Firestore
                      await _firestore
                          .collection('kayu')
                          .doc(widget.kayuId)
                          .update({
                        'jumlah_stok': newStock,
                        'updated_at': FieldValue.serverTimestamp(),
                        'catatan_stok': FieldValue.arrayUnion([
                          {
                            'tanggal': Timestamp.now(),
                            'jenis': isAddition ? 'tambah' : 'kurang',
                            'jumlah': amount,
                            'catatan': noteController.text,
                          }
                        ]),
                      });

                      Get.back(); // Tutup loading

                      // Update di controller juga
                      final index = kayuController.inventoryItems
                          .indexWhere((item) => item.id == widget.kayuId);
                      if (index != -1) {
                        // Update local data di controller
                        final item = kayuController.inventoryItems[index];
                        kayuController.inventoryItems[index] = InventoryItem(
                          id: item.id,
                          batch: item.batch,
                          stock: '$newStock Unit',
                          namaKayu: item.namaKayu,
                          jenisKayu: item.jenisKayu,
                          batchPanen: item.batchPanen,
                          imageUrl: item.imageUrl,
                          jumlahStok: newStock,
                        );

                        kayuController.updateCounts();
                      }

                      final action =
                          isAddition ? 'ditambahkan ke' : 'dikurangi dari';
                      Get.snackbar(
                        'Sukses',
                        '$amount unit berhasil $action stok',
                        backgroundColor:
                            isAddition ? Colors.green : Colors.orange,
                        colorText: Colors.white,
                      );

                      _fetchKayuData(); // Reload data
                    } catch (e) {
                      Get.back(); // Tutup loading jika terjadi error
                      Get.snackbar(
                        'Error',
                        'Gagal menyesuaikan stok: $e',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  } else {
                    Get.snackbar(
                      'Validasi',
                      'Jumlah harus lebih dari 0',
                      backgroundColor: Colors.orange,
                      colorText: Colors.white,
                    );
                  }
                } else {
                  Get.snackbar(
                    'Validasi',
                    'Jumlah tidak boleh kosong',
                    backgroundColor: Colors.orange,
                    colorText: Colors.white,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isAddition ? Colors.green : Colors.orange,
              ),
              child: Text('Konfirmasi'),
            ),
          ],
        );
      }),
    );
  }
}
