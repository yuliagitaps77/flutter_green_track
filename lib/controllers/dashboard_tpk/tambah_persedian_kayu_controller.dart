import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';
import 'package:flutter_green_track/fitur/lacak_history/user_activity_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/dashboard_tpk/controller_inventory_kayu.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'tambah_persedian_kayu_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'tambah_persedian_kayu_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'tambah_persedian_kayu_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'tambah_persedian_kayu_controller.dart';
import 'package:flutter_green_track/data/models/user_model.dart';
import 'package:flutter_green_track/fitur/navigation/navigation_page.dart';
import 'package:flutter_green_track/controllers/dashboard_tpk/dashboard_tpk_controller.dart';

class LocationData {
  final String kph;
  final Map<String, List<String>> bkphMap;
  final Map<String, List<String>> rkphMap; // RKPH to available petak sizes

  LocationData({
    required this.kph,
    required this.bkphMap,
    required this.rkphMap,
  });
}

class TambahPersediaanController extends GetxController {
  // Controllers for form fields
  final TextEditingController idController = TextEditingController();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController varietasController = TextEditingController();
  final TextEditingController usiaController = TextEditingController();
  final TextEditingController tinggiController = TextEditingController();
  final TextEditingController jenisController = TextEditingController();
  final TextEditingController lokasiController = TextEditingController();
  final TextEditingController jumlahStokController = TextEditingController();
  final TextEditingController tanggalController = TextEditingController();
  final TextEditingController batchPanenController = TextEditingController();
  var selectedImages = <String>[].obs;
  var isLoading = false.obs;
  final bool isAutoFill;

  /// Isi cepat field saat `isAutoFill == true`.
  void _applyDummyData() {
    // namaController.text = 'Kayu Jati Super';
    // varietasController.text = 'Tectona grandis';
    // usiaController.text = '5'; // tahun
    // tinggiController.text = '12'; // meter
    // jenisController.text = 'Jati';
    // jumlahStokController.text = '100'; // batang
    batchPanenController.text = '2025-A';
    // catatanController.text = 'Data dummy untuk keperluan testing.';

    // Tanggal tanam contoh
    //  selectedDate.value = DateTime(2020, 1, 15);
    _updateDateDisplay();

    // Jangan sentuh dropdown & gambar ⇢ biarkan user memilih sendiri
  }

  TambahPersediaanController({this.isAutoFill = true});

  // Add a text controller for catatan
  final TextEditingController catatanController = TextEditingController();

  // Store the selected date
  Rx<DateTime?> selectedDate = Rx<DateTime?>(null);

  // Observable for image path
  var imagePath = ''.obs;

  // Location dropdown values
  var selectedKPH = ''.obs;
  var selectedBKPH = ''.obs;
  var selectedRKPH = ''.obs;
  var selectedLuasPetak = ''.obs;
  var availableBKPHs = <String>[].obs;
  var availableRKPHs = <String>[].obs;
  var availableLuasPetak = <String>[].obs;

  // Create formatters for numeric fields
  late TextInputFormatter digitsOnly;
  late TextInputFormatter decimalOnly;

  // Dummy location data
  late List<LocationData> locationData;

  @override
  void onInit() {
    super.onInit();

    // Generate an ID for new inventory
    generateInventoryId();

    // Setup dummy location data
    setupLocationData();

    // Initialize formatters
    digitsOnly = FilteringTextInputFormatter.digitsOnly;
    decimalOnly = FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'));

    // Set default date to today
    // Tanggal default → hari ini
    selectedDate.value = DateTime.now();
    _updateDateDisplay();

    // ⇣ Tambahkan baris ini
    if (isAutoFill) _applyDummyData();
  }

  void setupLocationData() {
    locationData = [
      LocationData(
        kph: 'KPH Wilangan',
        bkphMap: {
          'BKPH Wilangan Utara': [
            'RKPH Wilangan A',
            'RKPH Wilangan B',
            'RKPH Wilangan C'
          ],
          'BKPH Wilangan Selatan': ['RKPH Wilangan D', 'RKPH Wilangan E'],
          'BKPH Wilangan Timur': ['RKPH Wilangan F', 'RKPH Wilangan G'],
        },
        rkphMap: {
          'RKPH Wilangan A': ['10 x 10', '20 x 30', '30 x 30'],
          'RKPH Wilangan B': ['20 x 30', '40 x 40', '50 x 50'],
          'RKPH Wilangan C': ['10 x 10', '30 x 30', '40 x 40'],
          'RKPH Wilangan D': ['20 x 30', '30 x 30', '50 x 50'],
          'RKPH Wilangan E': ['10 x 10', '40 x 40', '50 x 50'],
          'RKPH Wilangan F': ['30 x 30', '40 x 40', '50 x 50'],
          'RKPH Wilangan G': ['10 x 10', '20 x 30', '50 x 50'],
        },
      ),
      LocationData(
        kph: 'KPH Saradan',
        bkphMap: {
          'BKPH Saradan Utara': ['RKPH Saradan A', 'RKPH Saradan B'],
          'BKPH Saradan Selatan': ['RKPH Saradan C', 'RKPH Saradan D'],
        },
        rkphMap: {
          'RKPH Saradan A': ['10 x 10', '30 x 30', '50 x 50'],
          'RKPH Saradan B': ['20 x 30', '40 x 40', '50 x 50'],
          'RKPH Saradan C': ['10 x 10', '20 x 30', '40 x 40'],
          'RKPH Saradan D': ['30 x 30', '40 x 40', '50 x 50'],
        },
      ),
      LocationData(
        kph: 'KPH Bojonegoro',
        bkphMap: {
          'BKPH Bojonegoro Barat': ['RKPH Bojonegoro A', 'RKPH Bojonegoro B'],
          'BKPH Bojonegoro Timur': ['RKPH Bojonegoro C', 'RKPH Bojonegoro D'],
        },
        rkphMap: {
          'RKPH Bojonegoro A': ['10 x 10', '20 x 30', '50 x 50'],
          'RKPH Bojonegoro B': ['30 x 30', '40 x 40', '50 x 50'],
          'RKPH Bojonegoro C': ['10 x 10', '20 x 30', '40 x 40'],
          'RKPH Bojonegoro D': ['20 x 30', '30 x 30', '50 x 50'],
        },
      ),
    ];
  }

  List<String> getKPHList() {
    return locationData.map((location) => location.kph).toList();
  }

  void onKPHSelected(String kph) {
    selectedKPH.value = kph;
    selectedBKPH.value = '';
    selectedRKPH.value = '';
    selectedLuasPetak.value = '';

    // Find the corresponding location data
    final location = locationData.firstWhere(
      (loc) => loc.kph == kph,
      orElse: () => LocationData(kph: '', bkphMap: {}, rkphMap: {}),
    );

    // Update available BKPHs
    availableBKPHs.value = location.bkphMap.keys.toList();
    availableRKPHs.clear();
    availableLuasPetak.clear();

    // Update the location text field
    updateLocationText();
  }

  void onBKPHSelected(String bkph) {
    selectedBKPH.value = bkph;
    selectedRKPH.value = '';
    selectedLuasPetak.value = '';

    // Find the corresponding location data
    final location = locationData.firstWhere(
      (loc) => loc.kph == selectedKPH.value,
      orElse: () => LocationData(kph: '', bkphMap: {}, rkphMap: {}),
    );

    // Update available RKPHs
    availableRKPHs.value = location.bkphMap[bkph] ?? [];
    availableLuasPetak.clear();

    // Update the location text field
    updateLocationText();
  }

  void onRKPHSelected(String rkph) {
    selectedRKPH.value = rkph;
    selectedLuasPetak.value = '';

    // Find the corresponding location data
    final location = locationData.firstWhere(
      (loc) => loc.kph == selectedKPH.value,
      orElse: () => LocationData(kph: '', bkphMap: {}, rkphMap: {}),
    );

    // Update available luas petak options
    availableLuasPetak.value = location.rkphMap[rkph] ?? [];

    // Update the location text field
    updateLocationText();
  }

  void onLuasPetakSelected(String luasPetak) {
    selectedLuasPetak.value = luasPetak;

    // Update the location text field
    updateLocationText();
  }

  void updateLocationText() {
    List<String> locationParts = [];

    if (selectedKPH.value.isNotEmpty) {
      locationParts.add(selectedKPH.value);
    }

    if (selectedBKPH.value.isNotEmpty) {
      locationParts.add(selectedBKPH.value);
    }

    if (selectedRKPH.value.isNotEmpty) {
      locationParts.add(selectedRKPH.value);
    }

    if (selectedLuasPetak.value.isNotEmpty) {
      locationParts.add('Petak ${selectedLuasPetak.value}');
    }

    lokasiController.text = locationParts.join(' - ');
  }

  void generateInventoryId() {
    // Generate a unique ID with prefix
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    idController.text =
        'K_${timestamp.toString().substring(timestamp.toString().length - 6)}';
  }

  void pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedDate.value = picked;
      _updateDateDisplay();
    }
  }

  void _updateDateDisplay() {
    if (selectedDate.value != null) {
      // Format as day/month/year
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      tanggalController.text = formatter.format(selectedDate.value!);
    } else {
      tanggalController.text = '';
    }
  }

  bool isValidNumber(String value) {
    if (value.isEmpty) return false;

    // Try parsing as a number
    try {
      double.parse(value);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool validateInputs() {
    // Basic validation
    if (namaController.text.isEmpty ||
        varietasController.text.isEmpty ||
        jenisController.text.isEmpty ||
        // selectedRKPH.value.isEmpty ||
        // selectedLuasPetak.value.isEmpty ||
        jumlahStokController.text.isEmpty ||
        batchPanenController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Harap isi semua bidang wajib',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 3),
      );

      return false;
    }

    // Validate numeric fields
    if (!isValidNumber(usiaController.text)) {
      Get.snackbar(
        'Error',
        'Usia harus berupa angka',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    if (!isValidNumber(tinggiController.text)) {
      Get.snackbar(
        'Error',
        'Tinggi harus berupa angka',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    if (!isValidNumber(jumlahStokController.text)) {
      Get.snackbar(
        'Error',
        'Jumlah stok harus berupa angka',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    return true;
  }

  void updateSelectedImage() {
    if (selectedImages.isNotEmpty) {
      // Ensure the selected image is always the first image in the list
      selectedImages.insert(
          0, selectedImages.removeAt(selectedImages.length - 1));
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }

    // If the first image is removed, make sure the next one is selected
    if (selectedImages.isEmpty) {
      // Optionally, clear the `selectedImages` if no images remain
    } else if (index == 0 && selectedImages.isNotEmpty) {
      // Ensure the first image becomes the new selected one
      updateSelectedImage();
    }
  }

  // Image picker function
  Future<void> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image != null) {
      selectedImages.add(image.path);
    }
  }

  // Camera picker method
  Future<void> pickImageFromCamera() async {
    await pickImage(ImageSource.camera);
  }

  // Gallery picker method
  Future<void> pickImageFromGallery() async {
    await pickImage(ImageSource.gallery);
  }

// Image upload function
  Future<String?> uploadImageToFreeImageHost(String imagePath) async {
    try {
      print('⭐ Starting image upload for: $imagePath');
      final apiKey = '6d207e02198a847aa98d0a2a901485a5';
      final url = Uri.parse('https://freeimage.host/api/1/upload');

      print('⭐ Reading image bytes...');
      final imageBytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(imageBytes);
      print(
          '⭐ Image converted to base64, size: ${base64Image.length} characters');

      print('⭐ Sending upload request to API...');
      final response = await http.post(
        url,
        body: {
          'key': apiKey,
          'source': base64Image,
          'format': 'json',
        },
      );

      print('⭐ Response status code: ${response.statusCode}');
      print('⭐ Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final imageUrl = jsonResponse['image']['url'];
        print('⭐ Image uploaded successfully, URL: $imageUrl');
        return imageUrl;
      } else {
        print('❌ Upload failed with status code: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Error uploading image: $e');
      print('❌ Stack trace: $stackTrace');
      return null;
    }
  }

// Modified saveInventory function to save to Firestore with detailed logging
  Future<void> saveInventory() async {
    print('🔵 Starting saveInventory function');

    print('🔵 Validating inputs...');
    if (!validateInputs()) {
      print('❌ Input validation failed');
      return;
    }
    print('✅ Input validation passed');

    isLoading.value = true;
    print('🔵 Setting isLoading to true');

    try {
      // Upload images first
      print(
          '🔵 Starting image upload process for ${selectedImages.length} images');
      List<String> uploadedUrls = [];
      for (int i = 0; i < selectedImages.length; i++) {
        String path = selectedImages[i];
        print('🔵 Uploading image ${i + 1}/${selectedImages.length}: $path');
        final uploadedUrl = await uploadImageToFreeImageHost(path);
        if (uploadedUrl != null) {
          uploadedUrls.add(uploadedUrl);
          print('✅ Image ${i + 1} uploaded successfully: $uploadedUrl');
        } else {
          print('❌ Failed to upload image ${i + 1}');
          throw Exception("Upload gambar gagal untuk gambar ${i + 1}");
        }
      }
      print(
          '✅ All images uploaded successfully. Total URLs: ${uploadedUrls.length}');

      // Generate a barcode value
      final barcodeValue = 'KAYU-${DateTime.now().millisecondsSinceEpoch}';
      print('🔵 Generated barcode: $barcodeValue');

      // Get user ID
      print('🔵 Getting user ID from Firebase Auth');
      final userId = FirebaseAuth.instance.currentUser?.uid;
      print('🔵 Current user ID: $userId');
      if (userId == null) {
        print('❌ User ID is null. User not logged in');
        throw Exception("User tidak ditemukan. Harus login dulu.");
      }
      print('✅ User ID retrieved successfully');

      // Create the data structure
      print('🔵 Creating kayu data structure');
      final kayuData = {
        'id_kayu': idController.text,
        'id_user': userId,
        'nama_kayu': namaController.text,
        'varietas': varietasController.text,
        'usia': int.tryParse(usiaController.text) ?? 0,
        'tinggi': double.tryParse(tinggiController.text) ?? 0.0,
        'jenis_kayu': jenisController.text,
        'catatan': catatanController.text,
        'jumlah_stok': int.tryParse(jumlahStokController.text) ?? 0,
        'created_at': FieldValue.serverTimestamp(),
        'tanggal_lahir_pohon': selectedDate.value?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
        'gambar_image': uploadedUrls,
        'barcode': barcodeValue,
        'batch_panen': batchPanenController.text,
        'lokasi_tanam': {
          'kph': selectedKPH.value,
          'bkph': selectedBKPH.value,
          'rkph': selectedRKPH.value,
          'luas_petak': selectedLuasPetak.value,
          'lat': 0,
          'lng': 0,
          'alamat': lokasiController.text,
        },
        'updated_at': FieldValue.serverTimestamp(),
      };
      print('✅ Data structure created successfully');
      print('🔵 Data to be saved: $kayuData');
      AppController.to.recordActivity(
          activityType: ActivityTypes.addKayu,
          name: "${namaController.text} | ${jenisController.text}",
          metadata: {"kayu": kayuData});

      // Save to Firestore
      print(
          '🔵 Attempting to save to Firestore collection "kayu" with document ID: ${idController.text}');
      try {
        await FirebaseFirestore.instance
            .collection('kayu')
            .doc(idController.text)
            .set(kayuData)
            .timeout(const Duration(seconds: 30));
        print('✅ Document successfully saved to Firestore');

        // Update dashboard data after successful save
        try {
          final dashboardController = Get.find<TPKDashboardController>();
          await dashboardController.refreshDashboardData();
          print('✅ Dashboard data refreshed successfully');
        } catch (dashboardError) {
          print('⚠️ Warning: Could not refresh dashboard: $dashboardError');
        }

        // Add to local inventory
        print('🔵 Adding to local inventory through controller');
        try {
          final inventoryController = Get.find<InventoryKayuController>();
          final newItem = InventoryItem(
            id: idController.text,
            batch:
                '${jenisController.text} - Batch ${batchPanenController.text}',
            stock: '${jumlahStokController.text} Unit',
            jumlahStok: int.tryParse(jumlahStokController.text) ?? 0,
            namaKayu: namaController.text,
            jenisKayu: jenisController.text,
            batchPanen: batchPanenController.text,
            imageUrl: uploadedUrls.isNotEmpty ? uploadedUrls[0] : '',
          );

          // Add to the beginning of the list since we're using descending order
          inventoryController.inventoryItems.insert(0, newItem);
          inventoryController.updateCounts();

          // Trigger a manual refresh to ensure everything is in sync
          await inventoryController.fetchInventoryFromFirestore();
          print('✅ Item added to local inventory successfully');
        } catch (inventoryError) {
          print(
              '⚠️ Warning: Could not add to local inventory: $inventoryError');
        }

        // Show success message with styled snackbar
        print('🔵 Showing success message');
        Get.snackbar(
          'Sukses',
          'Persediaan kayu berhasil ditambahkan',
          backgroundColor: Color(0xFF4CAF50),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          borderRadius: 15,
          margin: const EdgeInsets.all(10),
          snackPosition: SnackPosition.BOTTOM,
          icon: Icon(Icons.check_circle, color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          titleText: Text(
            'Sukses',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          messageText: Text(
            'Persediaan kayu berhasil ditambahkan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
        );

        // Navigate back using Get.off
        print('🔵 Navigating back');
        Get.off(() => MainNavigationContainer(userRole: UserRole.adminTPK));
        print('✅ saveInventory function completed successfully');
      } catch (firestoreError, stackTrace) {
        print('❌ Firestore save operation failed');
        print('❌ Firestore error: $firestoreError');
        print('❌ Stack trace: $stackTrace');
        throw firestoreError;
      }
    } catch (e, stackTrace) {
      print('❌ Error in saveInventory function: $e');
      print('❌ Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Terjadi kesalahan saat menyimpan: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        borderRadius: 15,
        margin: const EdgeInsets.all(10),
        snackPosition: SnackPosition.BOTTOM,
        icon: Icon(Icons.error, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        titleText: Text(
          'Error',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        messageText: Text(
          'Terjadi kesalahan saat menyimpan: $e',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
      );
    } finally {
      print('🔵 Setting isLoading to false');
      isLoading.value = false;
    }
  }

// Add a debug function to check Firestore connection
  Future<void> checkFirestoreConnection() async {
    print('🔄 Testing Firestore connection...');
    try {
      // Try to fetch a small document to test connection
      final testRef =
          FirebaseFirestore.instance.collection('test').doc('connection_test');
      await testRef.set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': 'Connection test',
      });

      final result = await testRef.get();
      print('✅ Firestore connection successful');
      print('✅ Test document exists: ${result.exists}');
      print('✅ Test document data: ${result.data()}');
    } catch (e, stackTrace) {
      print('❌ Firestore connection failed');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }

// Call this function before attempting to save data
  void troubleshootFirestore() {
    print('🔄 Starting Firestore troubleshooting');
    checkFirestoreConnection().then((_) {
      print('🔄 Firestore connection check completed');
    });
  }

  @override
  void onClose() {
    // Dispose all controllers
    idController.dispose();
    namaController.dispose();
    varietasController.dispose();
    usiaController.dispose();
    tinggiController.dispose();
    jenisController.dispose();
    lokasiController.dispose();
    jumlahStokController.dispose();
    tanggalController.dispose();
    batchPanenController.dispose();
    catatanController.dispose();

    super.onClose();
  }
}
