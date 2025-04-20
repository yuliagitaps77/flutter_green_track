import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class BarcodeController extends GetxController {
  // Text controllers
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
  final urlBibitController = TextEditingController();
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
  final kphList =
      ['KPH Wilangan', 'KPH Saradan', 'KPH Bojonegoro', 'KPH Parengan'].obs;
  var bkphOptions = <String>[].obs;
  var rkphOptions = <String>[].obs;

  // Map of BKPH options based on KPH
  final Map<String, List<String>> bkphMap = {
    'KPH Wilangan': ['BKPH Wilangan Utara', 'BKPH Wilangan Selatan'],
    'KPH Saradan': ['BKPH Saradan Timur', 'BKPH Saradan Barat'],
    'KPH Bojonegoro': ['BKPH Bojonegoro A', 'BKPH Bojonegoro B'],
    'KPH Parengan': ['BKPH Parengan 1', 'BKPH Parengan 2'],
  };

  // Map of RKPH options based on BKPH
  final Map<String, List<String>> rkphMap = {
    'BKPH Wilangan Utara': ['80 x 10', '30 x 30', '40 x 40'],
    'BKPH Wilangan Selatan': ['50 x 20', '25 x 25'],
    'BKPH Saradan Timur': ['60 x 15', '35 x 35'],
    'BKPH Saradan Barat': ['45 x 25', '55 x 15'],
    'BKPH Bojonegoro A': ['70 x 20', '40 x 30'],
    'BKPH Bojonegoro B': ['65 x 25', '35 x 25'],
    'BKPH Parengan 1': ['55 x 30', '40 x 20'],
    'BKPH Parengan 2': ['50 x 40', '30 x 25'],
  };

  @override
  void onInit() {
    super.onInit();
    // Initialize tanggal pembibitan with current date
    tanggalPembibitanController.text =
        DateFormat('dd/MM/yyyy').format(DateTime.now());
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
    urlBibitController.dispose();
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

  // Submit form data
  void submitBibit() {
    // Create a map of the bibit data
    final bibitData = {
      'id_bibit': idBibitController.text,
      'nama_bibit': namaBibitController.text,
      'varietas': varietasController.text,
      'usia': usiaController.text,
      'tinggi': tinggiController.text,
      'jenis_bibit': jenisBibitController.text,
      'kondisi': kondisi.value,
      'status_hama': statusHama.value,
      'media_tanam': mediaTanamController.text,
      'nutrisi': nutrisiController.text,
      'asal_bibit': asalBibitController.text,
      'produktivitas': produktivitasController.text,
      'catatan': catatanController.text,
      'created_at': DateTime.now().toString(),
      'tanggal_pembibitan': tanggalPembibitan.value.toString(),
      'gambar_image': selectedImages,
      'url_bibit': urlBibitController.text,
      'lokasi_tanam': {
        'kph': selectedKPH.value,
        'bkph': selectedBKPH.value,
        'rkph': selectedRKPH.value,
      },
      'updated_at': DateTime.now().toString(),
    };

    // Here you would typically send the data to your API or save locally
    // For demonstration, we'll just print it and show a success message
    print('Data bibit yang akan disimpan: $bibitData');

    // Show success message
    Get.snackbar(
      'Sukses',
      'Barcode bibit berhasil dibuat.',
      backgroundColor: const Color(0xFF2E7D32),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );

    // Navigate to barcode view (this would be implemented in a real app)
    // Get.toNamed('/barcode-view', arguments: bibitData);

    // Or clear the form for new entry
    // resetForm();
  }

  // Reset form values
  void resetForm() {
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
    urlBibitController.clear();
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
