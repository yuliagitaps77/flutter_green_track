import 'dart:convert';
import 'dart:io';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';
import 'package:flutter_green_track/controllers/navigation/navigation_controller.dart';
import 'package:flutter_green_track/fitur/lacak_history/user_activity_model.dart';
import 'package:flutter_green_track/fitur/navigation/navigation_page.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/controller/controller_page_nav_bibit.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/model/model_bibit.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class BarcodeController extends GetxController {
  // Text controllers
  final Bibit? bibit = Get.arguments as Bibit?;
  bool get isEditMode => bibit != null;
  var isLoading = false.obs;

  final idBibitController = TextEditingController();
  final namaBibitController = TextEditingController();
  final varietasController = TextEditingController();
  final usiaController = TextEditingController();
  final tinggiController = TextEditingController();
  final jenisBibitController = TextEditingController();
  final mediaTanamController = TextEditingController();
  final nutrisiController = TextEditingController();
  final asalBibitController = TextEditingController();
  final produktivitasController = TextEditingController();
  final catatanController = TextEditingController();
  final tanggalPembibitanController = TextEditingController();
  void updateSelectedImage() {
    if (selectedImages.isNotEmpty) {
      // Ensure the selected image is always the first image in the list
      selectedImages.insert(
          0, selectedImages.removeAt(selectedImages.length - 1));
    }
  }

  // Remove image function
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

  void autoFillBibitForm() {
    generateIdBibit(); // Auto generate ID

    namaBibitController.text =
        'Jati Super A${DateTime.now().millisecondsSinceEpoch % 1000}';
    varietasController.text = 'Tectona grandis';
    usiaController.text = '30';
    tinggiController.text = '20';
    jenisBibitController.text = 'Kayu keras';
    // kondisi.value = 'Siap Tanam';
    // statusHama.value = 'Tidak ada';
    mediaTanamController.text = 'Polybag';
    nutrisiController.text = 'Pupuk NPK';
    asalBibitController.text = 'Kebun Induk Wilangan';
    produktivitasController.text = 'Tinggi';
    catatanController.text = 'Auto-generated untuk testing cepat.';

    // Lokasi tanam dummy
    // selectedKPH.value = 'KPH Wilangan';
    // loadBKPHOptions(selectedKPH.value);
    // selectedBKPH.value = bkphOptions.isNotEmpty ? bkphOptions.first : '';
    // loadRKPHOptions(selectedBKPH.value);
    // selectedRKPH.value = rkphOptions.isNotEmpty ? rkphOptions.first : '';

    // Tanggal pembibitan
    tanggalPembibitan.value = DateTime.now();
    tanggalPembibitanController.text =
        DateFormat('dd/MM/yyyy').format(tanggalPembibitan.value);

    print('✅ Data form bibit berhasil diisi otomatis.');
  }

  // Observable values
  var kondisi = ''.obs;
  var statusHama = ''.obs;
  var selectedKPH = ''.obs;
  var selectedBKPH = ''.obs;
  var selectedRKPH = ''.obs;
  var createdAt = DateTime.now().obs;
  var tanggalPembibitan = DateTime.now().obs;
  var selectedImages = <String>[].obs;

  // Dummy data for dropdown cascading
  var bkphOptions = <String>[].obs;
  var rkphOptions = <String>[].obs;

  // KPH List
  final kphList =
      ['KPH Wilangan', 'KPH Saradan', 'KPH Bojonegoro', 'KPH Parengan'].obs;

// Map of BKPH options based on KPH
  final Map<String, List<String>> bkphMap = {
    'KPH Wilangan': ['BKPH Wilangan Utara', 'BKPH Wilangan Selatan'],
    'KPH Saradan': ['BKPH Saradan Timur', 'BKPH Saradan Barat'],
    'KPH Bojonegoro': ['BKPH Bojonegoro A', 'BKPH Bojonegoro B'],
    'KPH Parengan': ['BKPH Parengan 1', 'BKPH Parengan 2'],
  };

// Map of RKPH options based on BKPH
  final Map<String, List<String>> rkphMap = {
    'BKPH Wilangan Utara': [
      'RKPH Wilangan A',
      'RKPH Wilangan B',
      'RKPH Wilangan C'
    ],
    'BKPH Wilangan Selatan': ['RKPH Wilangan D', 'RKPH Wilangan E'],
    'BKPH Saradan Timur': [
      'RKPH Saradan A',
      'RKPH Saradan B',
      'RKPH Saradan C'
    ],
    'BKPH Saradan Barat': [
      'RKPH Saradan D',
      'RKPH Saradan E',
      'RKPH Saradan F'
    ],
    'BKPH Bojonegoro A': [
      'RKPH Bojonegoro A1',
      'RKPH Bojonegoro A2',
      'RKPH Bojonegoro A3'
    ],
    'BKPH Bojonegoro B': [
      'RKPH Bojonegoro B1',
      'RKPH Bojonegoro B2',
      'RKPH Bojonegoro B3'
    ],
    'BKPH Parengan 1': [
      'RKPH Parengan 1A',
      'RKPH Parengan 1B',
      'RKPH Parengan 1C'
    ],
    'BKPH Parengan 2': [
      'RKPH Parengan 2A',
      'RKPH Parengan 2B',
      'RKPH Parengan 2C'
    ],
  };

// Map of Luas Petak options based on RKPH
  final Map<String, List<String>> luasPetakMap = {
    'RKPH Wilangan A': ['10 x 10', '20 x 30', '30 x 30'],
    'RKPH Wilangan B': ['20 x 30', '40 x 40', '50 x 50'],
    'RKPH Wilangan C': ['15 x 15', '25 x 25', '35 x 35'],
    'RKPH Wilangan D': ['20 x 20', '30 x 30', '40 x 40'],
    'RKPH Wilangan E': ['25 x 25', '35 x 35', '45 x 45'],
    'RKPH Saradan A': ['10 x 10', '20 x 20', '30 x 30'],
    'RKPH Saradan B': ['15 x 15', '25 x 25', '35 x 35'],
    'RKPH Saradan C': ['20 x 20', '30 x 30', '40 x 40'],
    'RKPH Saradan D': ['15 x 15', '25 x 25', '35 x 35'],
    'RKPH Saradan E': ['20 x 20', '30 x 30', '40 x 40'],
    'RKPH Saradan F': ['25 x 25', '35 x 35', '45 x 45'],
    'RKPH Bojonegoro A1': ['10 x 10', '20 x 20', '30 x 30'],
    'RKPH Bojonegoro A2': ['15 x 15', '25 x 25', '35 x 35'],
    'RKPH Bojonegoro A3': ['20 x 20', '30 x 30', '40 x 40'],
    'RKPH Bojonegoro B1': ['10 x 10', '20 x 20', '30 x 30'],
    'RKPH Bojonegoro B2': ['15 x 15', '25 x 25', '35 x 35'],
    'RKPH Bojonegoro B3': ['20 x 20', '30 x 30', '40 x 40'],
    'RKPH Parengan 1A': ['10 x 10', '20 x 20', '30 x 30'],
    'RKPH Parengan 1B': ['15 x 15', '25 x 25', '35 x 35'],
    'RKPH Parengan 1C': ['20 x 20', '30 x 30', '40 x 40'],
    'RKPH Parengan 2A': ['10 x 10', '20 x 20', '30 x 30'],
    'RKPH Parengan 2B': ['15 x 15', '25 x 25', '35 x 35'],
    'RKPH Parengan 2C': ['20 x 20', '30 x 30', '40 x 40'],
  };
  @override
  void onInit() {
    super.onInit();
    // Initialize tanggal pembibitan with current date
    tanggalPembibitanController.text =
        DateFormat('dd/MM/yyyy').format(DateTime.now());
    autoFillBibitForm(); // Auto-fill form for testing
  }

  @override
  void onClose() {
    // Dispose controllers to prevent memory leaks
    idBibitController.dispose();
    namaBibitController.dispose();
    varietasController.dispose();
    usiaController.dispose();
    tinggiController.dispose();
    jenisBibitController.dispose();
    mediaTanamController.dispose();
    nutrisiController.dispose();
    asalBibitController.dispose();
    produktivitasController.dispose();
    catatanController.dispose();
    tanggalPembibitanController.dispose();
    super.onClose();
  }

  // Generate a unique ID for the bibit
  void generateIdBibit() {
    var uuid = const Uuid();
    String shortUuid = uuid.v4().substring(0, 8).toUpperCase();
    idBibitController.text = 'BBT-$shortUuid';
  }

  // Load BKPH options based on selected KPH
  void loadBKPHOptions(String kph) {
    bkphOptions.assignAll(bkphMap[kph] ?? []);
  }

  // Load RKPH options based on selected BKPH
  void loadRKPHOptions(String bkph) {
    rkphOptions.assignAll(rkphMap[bkph] ?? []);
  }

  // Date picker function
  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: tanggalPembibitan.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF2E7D32),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      tanggalPembibitan.value = picked;
      tanggalPembibitanController.text =
          DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  // Image picker function (Generalized for both camera and gallery)
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

  Future<String?> uploadImageToFreeImageHost(String imagePath) async {
    try {
      final apiKey = '6d207e02198a847aa98d0a2a901485a5';
      final url = Uri.parse('https://freeimage.host/api/1/upload');

      final imageBytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        url,
        body: {
          'key': apiKey,
          'source': base64Image,
          'format': 'json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final imageUrl = jsonResponse['image']['url'];
        return imageUrl;
      } else {
        print('Upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> saveBibitToFirestore(
      Map<String, dynamic> bibitData, bool isUpdate) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        throw Exception("User tidak ditemukan. Harus login dulu.");
      }

      bibitData['id_user'] = userId;
      if (isUpdate) {
        AppController.to.recordActivity(
          activityType: ActivityTypes.updateBibit,
          name: '${namaBibitController.text}',
          targetId: idBibitController.text,
          metadata: {
            'barcode': idBibitController.text,
            'id_bibit': idBibitController.text,
            'nama_bibit': namaBibitController.text,
            'varietas': varietasController.text,
            'usia': int.tryParse(usiaController.text) ?? 0,
            'tinggi': int.tryParse(tinggiController.text) ?? 0,
            'jenis_bibit': jenisBibitController.text,
            'kondisi': kondisi.value,
            'status_hama': statusHama.value,
            'media_tanam': mediaTanamController.text,
            'nutrisi': nutrisiController.text,
            'asal_bibit': asalBibitController.text,
            'produktivitas': produktivitasController.text,
            'catatan': catatanController.text,
            'gambar_image': selectedImages, // URL ya, kalau upload
            'lokasi_tanam': {
              'kph': selectedKPH.value,
              'bkph': selectedBKPH.value,
              'rkph': selectedRKPH.value,
            },
            'tanggal_pembibitan': tanggalPembibitan.value,
            'updated_at': DateTime.now(),
            'timestamp': DateTime.now().toString(),
          },
        );
      } else {
        AppController.to.recordActivity(
          activityType: ActivityTypes.printBarcode,
          name: '${namaBibitController.text}',
          targetId: idBibitController.text,
          metadata: {
            'barcode': idBibitController.text,
            'id_bibit': idBibitController.text,
            'nama_bibit': namaBibitController.text,
            'varietas': varietasController.text,
            'usia': int.tryParse(usiaController.text) ?? 0,
            'tinggi': int.tryParse(tinggiController.text) ?? 0,
            'jenis_bibit': jenisBibitController.text,
            'kondisi': kondisi.value,
            'status_hama': statusHama.value,
            'media_tanam': mediaTanamController.text,
            'nutrisi': nutrisiController.text,
            'asal_bibit': asalBibitController.text,
            'produktivitas': produktivitasController.text,
            'catatan': catatanController.text,
            'gambar_image': selectedImages, // URL ya, kalau upload
            'lokasi_tanam': {
              'kph': selectedKPH.value,
              'bkph': selectedBKPH.value,
              'rkph': selectedRKPH.value,
            },
            'tanggal_pembibitan': tanggalPembibitan.value,
            'updated_at': DateTime.now(),
            'timestamp': DateTime.now().toString(),
          },
        );
      }
      await FirebaseFirestore.instance
          .collection('bibit')
          .doc(bibitData['id_bibit'])
          .set(bibitData);

      Get.snackbar(
        'Sukses',
        'Bibit berhasil disimpan ke database.',
        backgroundColor: const Color(0xFF2E7D32),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      // Refresh daftar bibit dan kembali
      await Get.find<BibitController>().fetchBibitFromFirestore();
      await Get.find<BibitController>().fetchJenisList();
      final userRole = Get.find<AuthenticationController>()
          .currentUser
          .value; // Assuming you have an AuthController with userRole
      // Or however you get the current user role in your app
      Get.offAll(() => MainNavigationContainer(userRole: userRole!.role));
      navigationController.navigateToInventory();

      resetForm();
    } catch (e) {
      print('Gagal menyimpan bibit: $e');
      Get.snackbar(
        'Error',
        'Gagal menyimpan bibit. Coba lagi.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  var selectedLuasPetak = ''.obs; // Add this new observable
  // Available options for dropdowns
  var luasPetakOptions = <String>[].obs; // Add this new observable

  final navigationController = Get.find<NavigationController>();
// Before setting the options, remove duplicates
  void loadLuasPetakOptions(String rkph) {
    var options = luasPetakMap[rkph] ?? [];
    // Remove duplicates by converting to Set and back to List
    options = options.toSet().toList();
    luasPetakOptions.assignAll(options);
  }

  // Update the RKPH selection method to reset the Luas Petak selection
  void onRKPHSelected(String rkph) {
    selectedRKPH.value = rkph;
    selectedLuasPetak.value = '';
    loadLuasPetakOptions(rkph);
  }

  // Add method for Luas Petak selection
  void onLuasPetakSelected(String luasPetak) {
    selectedLuasPetak.value = luasPetak;
  }

  // Submit form data
  Future<void> submitBibit({bool isUpdate = false}) async {
    isLoading.value = true;

    // Validasi field wajib
    List<String> errors = [];
    if (selectedLuasPetak.value.isEmpty) {
      errors.add("Luas Petak");
    }
    if (namaBibitController.text.isEmpty) errors.add("Nama Bibit");
    if (jenisBibitController.text.isEmpty) errors.add("Jenis Bibit");
    if (kondisi.value.isEmpty) errors.add("Kondisi");
    if (statusHama.value.isEmpty) errors.add("Status Hama");
    if (mediaTanamController.text.isEmpty) errors.add("Media Tanam");
    if (nutrisiController.text.isEmpty) errors.add("Nutrisi");
    if (asalBibitController.text.isEmpty) errors.add("Asal Bibit");
    if (selectedKPH.value.isEmpty) errors.add("KPH");
    if (selectedBKPH.value.isEmpty) errors.add("BKPH");
    if (selectedRKPH.value.isEmpty) errors.add("RKPH");

    if (selectedImages.isEmpty) {
      errors.add("Minimal 1 Gambar");
    }

    if (errors.isNotEmpty) {
      isLoading.value = false;
      Get.snackbar(
        "Form Tidak Lengkap",
        "Harap lengkapi: ${errors.join(', ')}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    try {
      // Upload gambar
      List<String> uploadedUrls = [];

      for (String path in selectedImages) {
        final uploadedUrl = await uploadImageToFreeImageHost(path);
        if (uploadedUrl != null) {
          uploadedUrls.add(uploadedUrl);
        } else {
          throw Exception("Upload gambar gagal");
        }
      }

      final bibitData = {
        'id_bibit': idBibitController.text,
        'nama_bibit': namaBibitController.text,
        'varietas': varietasController.text,
        'usia': int.tryParse(usiaController.text) ?? 0,
        'tinggi': int.tryParse(tinggiController.text) ?? 0,
        'jenis_bibit': jenisBibitController.text,
        'kondisi': kondisi.value,
        'status_hama': statusHama.value,
        'media_tanam': mediaTanamController.text,
        'nutrisi': nutrisiController.text,
        'asal_bibit': asalBibitController.text,
        'produktivitas': produktivitasController.text,
        'catatan': catatanController.text,
        'tanggal_pembibitan': tanggalPembibitan.value,
        'gambar_image': uploadedUrls,
        'lokasi_tanam': {
          'kph': selectedKPH.value,
          'bkph': selectedBKPH.value,
          'rkph': selectedRKPH.value,
          'luas_petak': selectedLuasPetak.value,
        },
        'updated_at': DateTime.now(),
        if (!isUpdate) 'created_at': DateTime.now(),
      };

      await saveBibitToFirestore(bibitData, isUpdate);

      // Pastikan loading berhenti dan kembali ke halaman sebelumnya
      isLoading.value = false;
      Get.back();

      // Tampilkan snackbar sukses
      Get.snackbar(
        'Sukses',
        'Bibit berhasil disimpan ke database.',
        backgroundColor: const Color(0xFF2E7D32),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );

      // Refresh data
      await Get.find<BibitController>().fetchBibitFromFirestore();
      await Get.find<BibitController>().fetchJenisList();
      navigationController.navigateToInventory();
    } catch (e) {
      print("Error saat simpan bibit: $e");
      isLoading.value = false;
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // Reset form values
  void resetForm() {
    selectedLuasPetak.value = '';
    luasPetakOptions.clear();
    generateIdBibit(); // Generate new ID
    namaBibitController.clear();
    varietasController.clear();
    usiaController.clear();
    tinggiController.clear();
    jenisBibitController.clear();
    kondisi.value = '';
    statusHama.value = '';
    mediaTanamController.clear();
    nutrisiController.clear();
    asalBibitController.clear();
    produktivitasController.clear();
    catatanController.clear();
    selectedKPH.value = '';
    selectedBKPH.value = '';
    selectedRKPH.value = '';
    bkphOptions.clear();
    rkphOptions.clear();
    tanggalPembibitan.value = DateTime.now();
    tanggalPembibitanController.text =
        DateFormat('dd/MM/yyyy').format(DateTime.now());
    selectedImages.clear();
  }
}
