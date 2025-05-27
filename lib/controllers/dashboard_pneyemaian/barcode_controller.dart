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

  // Dropdown related properties
  final RxString selectedJenisBibit = ''.obs;
  final RxList<String> jenisBibitList = <String>[].obs;

  // Predefined lists for dropdowns
  final List<String> kondisiList = [
    'Siap Tanam',
    'Baik',
    'Sedang',
    'Buruk',
    'Belum Siap Tanam'
  ];

  final List<String> statusHamaList = [
    'Tidak ada',
    'Ringan',
    'Sedang',
    'Berat'
  ];

  final List<String> mediaTanamList = [
    'Polybag',
    'Tanah',
    'Tanah + Kompos',
    'Tanah + Sekam',
    'Tanah + Pupuk Kandang'
  ];

  final List<String> nutrisiList = [
    'NPK',
    'Urea',
    'KCL',
    'TSP',
    'Pupuk Organik',
    'Pupuk Kandang',
    'Kompos'
  ];

  final List<String> asalBibitList = [
    'Cangkok',
    'Stek',
    'Okulasi',
    'Sambung Pucuk',
    'Merunduk',
    'Kultur Jaringan'
  ];

  final List<String> produktivitasList = [
    'Sangat Tinggi',
    'Tinggi',
    'Sedang',
    'Rendah',
    'Sangat Rendah',
    'Belum Produktif'
  ];

  final List<String> jenisBibitOptions = ['Buah', 'Kayu'];

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
    loadJenisBibitList();
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

      // Jika mode edit dan tidak ada gambar baru, hapus field gambar dari data yang akan diupdate
      if (isUpdate && selectedImages.isEmpty) {
        bibitData.remove('gambar_image');
      }

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
            'gambar_image':
                selectedImages.isEmpty ? bibit?.gambarImage : selectedImages,
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
            'gambar_image': selectedImages,
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

      // Jika mode edit dan tidak ada gambar baru, gunakan update() untuk tidak mengubah field gambar
      if (isUpdate && selectedImages.isEmpty) {
        await FirebaseFirestore.instance
            .collection('bibit')
            .doc(bibitData['id_bibit'])
            .update(bibitData);
      } else {
        await FirebaseFirestore.instance
            .collection('bibit')
            .doc(bibitData['id_bibit'])
            .set(bibitData);
      }

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
      final userRole = Get.find<AuthenticationController>().currentUser.value;
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

    // Hanya validasi gambar kosong jika bukan mode edit
    if (!isUpdate && selectedImages.isEmpty) {
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
      List<String> uploadedUrls = [];

      // Jika ada gambar baru yang dipilih, upload gambar-gambar tersebut
      if (selectedImages.isNotEmpty) {
        for (String path in selectedImages) {
          final uploadedUrl = await uploadImageToImgBB(path);
          if (uploadedUrl != null) {
            uploadedUrls.add(uploadedUrl);
          } else {
            throw Exception("Upload gambar gagal");
          }
        }
      } else if (isUpdate && bibit != null) {
        // Jika mode edit dan tidak ada gambar baru, gunakan gambar yang sudah ada
        uploadedUrls = List<String>.from(bibit!.gambarImage);
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

      // Pastikan loading berhenti
      isLoading.value = false;

      // Buat objek Bibit baru dengan data yang diupdate
      final updatedBibit = Bibit(
        id: bibitData['id_bibit'] as String,
        namaBibit: bibitData['nama_bibit'] as String,
        varietas: bibitData['varietas'] as String,
        usia: bibitData['usia'] as int,
        tinggi: bibitData['tinggi'] as int,
        jenisBibit: bibitData['jenis_bibit'] as String,
        kondisi: bibitData['kondisi'] as String,
        statusHama: bibitData['status_hama'] as String,
        mediaTanam: bibitData['media_tanam'] as String,
        nutrisi: bibitData['nutrisi'] as String,
        asalBibit: bibitData['asal_bibit'] as String,
        produktivitas: bibitData['produktivitas'] as String,
        catatan: bibitData['catatan'] as String,
        gambarImage: uploadedUrls, // Gunakan uploadedUrls yang sudah diproses
        kph: (bibitData['lokasi_tanam'] as Map)['kph'] as String,
        bkph: (bibitData['lokasi_tanam'] as Map)['bkph'] as String,
        rkph: (bibitData['lokasi_tanam'] as Map)['rkph'] as String,
        tanggalPembibitan: bibitData['tanggal_pembibitan'] as DateTime,
        urlBibit: bibit?.urlBibit ?? '',
        createdAt: bibit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

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

      // Kembali ke halaman detail dengan data yang diupdate
      Get.back(result: updatedBibit);

      // Navigasi ke inventory setelah data berhasil disimpan
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

  void loadJenisBibitList() {
    // Load jenis bibit list from predefined options
    jenisBibitList.value = jenisBibitOptions;
  }

  void setJenisBibit(String value) {
    // Normalize the value first
    String normalizedValue = normalizeJenisBibitValue(value);
    if (jenisBibitList.contains(normalizedValue)) {
      selectedJenisBibit.value = normalizedValue;
      jenisBibitController.text = normalizedValue;
    } else {
      // If value is not in list, set to first option
      selectedJenisBibit.value = jenisBibitList.first;
      jenisBibitController.text = jenisBibitList.first;
    }
  }

  String normalizeJenisBibitValue(String value) {
    // Convert common variations to standard values
    Map<String, String> normalizations = {
      'Buah': 'Buah',
      'Kayu': 'Kayu',
      'Bibit Buah': 'Buah',
      'Bibit Kayu': 'Kayu',
      'Tanaman Buah': 'Buah',
      'Tanaman Kayu': 'Kayu'
    };

    // If the value exists in normalizations, return the normalized value
    if (normalizations.containsKey(value)) {
      return normalizations[value]!;
    }

    // If no match found, return the first option as default
    return jenisBibitOptions.first;
  }

  void setKondisi(String value) {
    if (kondisiList.contains(value)) {
      kondisi.value = value;
    }
  }

  void setStatusHama(String value) {
    if (statusHamaList.contains(value)) {
      statusHama.value = value;
    }
  }

  void setMediaTanam(String value) {
    if (mediaTanamList.contains(value)) {
      mediaTanam.value = value;
      mediaTanamController.text = value;
    }
  }

  void setNutrisi(String value) {
    if (nutrisiList.contains(value)) {
      nutrisi.value = value;
      nutrisiController.text = value;
    }
  }

  void setAsalBibit(String value) {
    if (asalBibitList.contains(value)) {
      asalBibit.value = value;
      asalBibitController.text = value;
    }
  }

  void setProduktivitas(String value) {
    if (produktivitasList.contains(value)) {
      produktivitas.value = value;
      produktivitasController.text = value;
    }
  }

  // Helper method to normalize dropdown values
  String normalizeDropdownValue(String value, List<String> validOptions) {
    // Convert common variations to standard values
    if (value == 'Tidak Ada') return 'Tidak ada';
    if (value == 'Siap Tanam') return 'Baik';

    // If the value exists in valid options, return it
    if (validOptions.contains(value)) return value;

    // If no match found, return the first option as default
    return validOptions.first;
  }
}
