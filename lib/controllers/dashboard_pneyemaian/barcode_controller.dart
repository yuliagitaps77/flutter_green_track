import 'dart:convert';
import 'dart:io';
import 'dart:developer' as dev;
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

  // Add new RxString for jenisBibit
  final jenisBibit = "".obs;

  // Add new RxString for nutrisi and asalBibit
  final nutrisi = "".obs;
  final asalBibit = "".obs;

  // Add new RxString for mediaTanam
  final mediaTanam = "".obs;

  // Add new RxString for produktivitas
  final produktivitas = "".obs;

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
    kondisi.value = 'Baik';
    statusHama.value = 'Tidak ada';
    mediaTanamController.text = 'Polybag';
    nutrisiController.text = 'Pupuk NPK';
    asalBibitController.text = 'Kebun Induk Wilangan';
    produktivitasController.text = 'Tinggi';
    catatanController.text = 'Auto-generated untuk testing cepat.';

    // Lokasi tanam dengan data baru
    selectedKPH.value = 'KPH Nganjuk';
    loadBKPHOptions(selectedKPH.value);
    if (bkphOptions.isNotEmpty) {
      selectedBKPH.value = bkphOptions.first;
      loadRKPHOptions(selectedBKPH.value);
      if (rkphOptions.isNotEmpty) {
        selectedRKPH.value = rkphOptions.first;
      }
    }

    // Tanggal pembibitan
    tanggalPembibitan.value = DateTime.now();
    tanggalPembibitanController.text =
        DateFormat('dd-MM-yyyy').format(tanggalPembibitan.value);

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

  // KPH List with Bagian Hutan (BH)
  final kphList = ['KPH Nganjuk'].obs;

  // Map of Bagian Hutan areas
  final Map<String, Map<String, double>> bagianHutanMap = {
    'KPH Nganjuk': {
      'BH Berbek': 8658.80,
      'BH Tritik': 12635.42,
    },
  };

  // Map of BKPH options and their areas
  final Map<String, List<String>> bkphMap = {
    'KPH Nganjuk': [
      'BKPH Berbek',
      'BKPH Bagor',
      'BKPH Tritik',
      'BKPH Tamanan',
      'BKPH Wengkal'
    ],
  };

  // Map of BKPH areas
  final Map<String, double> luasBKPHMap = {
    'BKPH Berbek': 4100.44,
    'BKPH Bagor': 4558.36,
    'BKPH Tritik': 5370.84,
    'BKPH Tamanan': 3613.73,
    'BKPH Wengkal': 3650.85,
  };

  // Map of RKPH options based on BKPH
  final Map<String, List<String>> rkphMap = {
    'BKPH Berbek': [
      'RPH Tirip',
      'RPH Maguan',
      'RPH Klonggean',
      'RPH Suwaru',
      'RPH Jatirejo'
    ],
    'BKPH Bagor': [
      'RPH Awar Awar',
      'RPH Malangbong',
      'RPH Tunglur',
      'RPH Gawok',
      'RPH Sudimorogeneng'
    ],
    'BKPH Tritik': [
      'RPH Tritik',
      'RPH Turi',
      'RPH Jeruk',
      'RPH Bendosewu',
      'RPH Kedungrejo'
    ],
    'BKPH Tamanan': ['RPH Tamanan', 'RPH Wedegan', 'RPH Brengkok', 'RPH Balo'],
    'BKPH Wengkal': [
      'RPH Wengkal',
      'RPH Senggowar',
      'RPH Ngluyu',
      'RPH Cabean'
    ],
  };

  // Map of RPH areas
  final Map<String, double> luasAreaMap = {
    'RPH Tirip': 716.10,
    'RPH Maguan': 832.49,
    'RPH Klonggean': 884.00,
    'RPH Suwaru': 847.97,
    'RPH Jatirejo': 819.88,
    'RPH Awar Awar': 944.04,
    'RPH Malangbong': 783.74,
    'RPH Tunglur': 943.00,
    'RPH Gawok': 886.23,
    'RPH Sudimorogeneng': 1001.35,
    'RPH Tritik': 1160.08,
    'RPH Turi': 1065.23,
    'RPH Jeruk': 892.33,
    'RPH Bendosewu': 974.15,
    'RPH Kedungrejo': 1279.05,
    'RPH Tamanan': 1037.47,
    'RPH Wedegan': 740.77,
    'RPH Brengkok': 935.92,
    'RPH Balo': 899.57,
    'RPH Wengkal': 923.66,
    'RPH Senggowar': 793.97,
    'RPH Ngluyu': 962.64,
    'RPH Cabean': 970.58,
  };

  final navigationController = Get.find<NavigationController>();

  @override
  void onInit() {
    super.onInit();
    // Initialize with empty values
    selectedKPH.value = '';
    selectedBKPH.value = '';
    selectedRKPH.value = '';
    // Initialize tanggal pembibitan with current date
    tanggalPembibitanController.text =
        DateFormat('dd-MM-yyyy').format(DateTime.now());
    selectedImages.clear();
    // autoFillBibitForm(); // Auto-fill form for testing
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

  Future<String?> uploadImageToImgBB(String imagePath) async {
    try {
      final apiKey = '558a46a506db3bfdce88d81f9e5c7e19';
      final url = Uri.parse('https://api.imghippo.com/v1/upload');

      // Create multipart request
      var request = http.MultipartRequest('POST', url);

      // Add API key
      request.fields['api_key'] = apiKey;

      // Add file
      var file = await http.MultipartFile.fromPath('file', imagePath);
      request.files.add(file);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // Log complete response for debugging
        dev.log('=== COMPLETE IMGHIPPO API RESPONSE ===', name: 'ImageUpload');
        dev.log('Raw Response: ${response.body}', name: 'ImageUpload');
        dev.log('Success: ${jsonResponse['success']}', name: 'ImageUpload');
        dev.log('Status: ${jsonResponse['status']}', name: 'ImageUpload');
        dev.log(
            'Image Details: ${JsonEncoder.withIndent('  ').convert(jsonResponse['data'])}',
            name: 'ImageUpload');

        // Get the view URL from the response
        final imageUrl = jsonResponse['data']['view_url'];
        dev.log('Image URL: $imageUrl', name: 'ImageUpload');

        // Log detailed image information
        dev.log('''
Image Details:
- Title: ${jsonResponse['data']['title']}
- Size: ${jsonResponse['data']['size']} bytes
- Extension: ${jsonResponse['data']['extension']}
- Created At: ${jsonResponse['data']['created_at']}
''', name: 'ImageUpload');

        return imageUrl;
      } else {
        dev.log('Upload failed: ${response.statusCode}', name: 'ImageUpload');
        dev.log('Response body: ${response.body}', name: 'ImageUpload');
        return null;
      }
    } catch (e) {
      dev.log('Error uploading image: $e', name: 'ImageUpload', error: e);
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
      // Get.offAll(() => MainNavigationContainer(userRole: userRole!.role));
      Navigator.of(Get.context!).pop();
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

  // Submit form data
  Future<void> submitBibit({bool isUpdate = false}) async {
    isLoading.value = true;

    // Validasi field wajib
    List<String> errors = [];
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
        final uploadedUrl = await uploadImageToImgBB(path);
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
          'luas_area': {
            'bkph_total': getSelectedBKPHArea(),
            'rph': getSelectedRPHArea(),
          },
          'bagian_hutan': getSelectedBagianHutanArea(),
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
    selectedKPH.value = '';
    selectedBKPH.value = '';
    selectedRKPH.value = '';
    bkphOptions.clear();
    rkphOptions.clear();
    selectedImages.clear();
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
    tanggalPembibitanController.text =
        DateFormat('dd-MM-yyyy').format(DateTime.now());
  }

  // Update BKPH options when KPH is selected
  void updateBKPHOptions(String kph) {
    bkphOptions.value = bkphMap[kph] ?? [];
    selectedBKPH.value = '';
    selectedRKPH.value = '';
  }

  // Update RKPH options when BKPH is selected
  void updateRKPHOptions(String bkph) {
    rkphOptions.value = rkphMap[bkph] ?? [];
    selectedRKPH.value = '';
  }

  // Get area for selected RPH
  double getSelectedRPHArea() {
    return luasAreaMap[selectedRKPH.value] ?? 0.0;
  }

  // Get area for selected BKPH
  double getSelectedBKPHArea() {
    return luasBKPHMap[selectedBKPH.value] ?? 0.0;
  }

  // Get area for selected Bagian Hutan
  double getSelectedBagianHutanArea() {
    if (selectedKPH.value.isEmpty) return 0.0;
    final bhMap = bagianHutanMap[selectedKPH.value];
    if (bhMap == null) return 0.0;
    return bhMap.values.reduce((a, b) => a + b);
  }
}
