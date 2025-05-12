import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/barcode_controller.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/model/model_bibit.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CetakBarcodeBibitPage extends StatefulWidget {
  static String routeName = "/cetak-barcode-bibit";

  const CetakBarcodeBibitPage({Key? key}) : super(key: key);

  @override
  State<CetakBarcodeBibitPage> createState() => _CetakBarcodeBibitPageState();
}

class _CetakBarcodeBibitPageState extends State<CetakBarcodeBibitPage> {
  final BarcodeController controller = Get.put(BarcodeController());
  final _formKey = GlobalKey<FormState>();
  bool get isEditMode => bibit != null;
  final Bibit? bibit = Get.arguments as Bibit?;

  @override
  void initState() {
    super.initState();
    controller.generateIdBibit();
    if (isEditMode) {
      final b = bibit!;
      controller.idBibitController.text = b.id;
      controller.namaBibitController.text = b.namaBibit;
      controller.varietasController.text = b.varietas;
      controller.usiaController.text = b.usia.toString();
      controller.tinggiController.text = b.tinggi.toString();
      controller.jenisBibitController.text = b.jenisBibit;
      controller.kondisi.value = b.kondisi;
      controller.statusHama.value = b.statusHama;
      controller.mediaTanamController.text = b.mediaTanam;
      controller.nutrisiController.text = b.nutrisi;
      controller.asalBibitController.text = b.asalBibit;
      controller.produktivitasController.text = b.produktivitas;
      controller.catatanController.text = b.catatan;
      controller.selectedKPH.value = b.kph;
      controller.loadBKPHOptions(b.kph);
      controller.selectedBKPH.value = b.bkph;
      controller.loadRKPHOptions(b.bkph);
      controller.selectedRKPH.value = b.rkph;
      controller.tanggalPembibitan.value = b.tanggalPembibitan;
      controller.tanggalPembibitanController.text =
          DateFormat('dd/MM/yyyy').format(b.tanggalPembibitan);
      // Gambar tidak di-preload karena tidak disimpan sebagai file lokal
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            isEditMode ? "Update Informasi Bibit" : 'Cetak Barcode Bibit Baru'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFF5F9F5),
              Color(0xFFEDF7ED),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Obx(() {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Picker Section with center rounded border
                    Center(
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(
                            color: const Color(0xFF2E7D32),
                            width: 1.5,
                          ),
                        ),
                        child: controller.selectedImages.isEmpty
                            ? Center(
                                child: Icon(Icons.forest_rounded,
                                    size: 100, color: const Color(0xFF2E7D32)),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(34),
                                child: Image.file(
                                  File(controller.selectedImages.first),
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),

// Display all images, including the main image, below
                    if (controller.selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120, // Set height to display images vertically
                        child: ReorderableListView(
                          scrollDirection: Axis.horizontal,
                          onReorder: (oldIndex, newIndex) {
                            // Reorder the images list
                            final image =
                                controller.selectedImages.removeAt(oldIndex);
                            controller.selectedImages.insert(newIndex, image);

                            // If the reordered image is now at index 0, it becomes the main image
                            if (newIndex == 0) {
                              controller.updateSelectedImage();
                            }
                          },
                          children: List.generate(
                              controller.selectedImages.length, (index) {
                            return Padding(
                              key: Key(controller
                                  .selectedImages[index]), // Key for reordering
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Stack(
                                clipBehavior: Clip
                                    .none, // Allow the delete button to overlap the image
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(controller.selectedImages[index]),
                                      width: 100, // Set width of each image
                                      height: 100, // Set height of each image
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: -8,
                                    right: -8,
                                    child: GestureDetector(
                                      onTap: () {
                                        controller.removeImage(
                                            index); // Remove the image at index
                                      },
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.red,
                                        child: const Icon(
                                          Icons.delete,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Add Image Button (circle with plus sign)
                    Center(
                      child: InkWell(
                        onTap: () => _showImageSourceOptions(context),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.add,
                              color: Color(0xFF2E7D32),
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ID Bibit Section
                    const Text(
                      'ID Bibit (otomatis)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: TextFormField(
                        controller: controller.idBibitController,
                        readOnly: true,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4A4A4A),
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: InputBorder.none,
                          hintText: 'ID otomatis diberikan',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Nama Bibit Section
                    const Text(
                      'Nama Bibit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: TextFormField(
                        controller: controller.namaBibitController,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4A4A4A),
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: InputBorder.none,
                          hintText: 'Contoh: Mangga',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama bibit tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Varietas Section
                    const Text(
                      'Varietas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: TextFormField(
                        controller: controller.varietasController,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4A4A4A),
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: InputBorder.none,
                          hintText: 'Contoh: Arumanis',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Usia Section
                    const Text(
                      'Usia (hari)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: TextFormField(
                        controller: controller.usiaController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4A4A4A),
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: InputBorder.none,
                          hintText: 'Contoh: 30',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tinggi Section
                    const Text(
                      'Tinggi (cm)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: TextFormField(
                        controller: controller.tinggiController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4A4A4A),
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: InputBorder.none,
                          hintText: 'Contoh: 25',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Jenis Bibit Section
                    const Text(
                      'Jenis Bibit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: TextFormField(
                        controller: controller.jenisBibitController,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4A4A4A),
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: InputBorder.none,
                          hintText: 'Contoh: Buah',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Kondisi Section
                    const Text(
                      'Kondisi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: controller.kondisi.value.isEmpty
                            ? null
                            : controller.kondisi.value,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          border: InputBorder.none,
                          hintText: 'Pilih kondisi bibit',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4A4A4A),
                        ),
                        items: ['Baik', 'Sedang', 'Buruk'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          controller.kondisi.value = value ?? '';
                        },
                      ),
                    ),

                    // Add more fields with similar styling...
                    // Continuing with similar pattern for all fields

                    const SizedBox(height: 16),

                    // Status Hama Section
                    const Text(
                      'Status Hama',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: controller.statusHama.value.isEmpty
                            ? null
                            : controller.statusHama.value,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          border: InputBorder.none,
                          hintText: 'Pilih status hama',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4A4A4A),
                        ),
                        items: ['Tidak Ada', 'Ringan', 'Sedang', 'Berat']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          controller.statusHama.value = value ?? '';
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Media Tanam Section
                    const Text(
                      'Media Tanam',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: TextFormField(
                        controller: controller.mediaTanamController,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4A4A4A),
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: InputBorder.none,
                          hintText: 'Contoh: Tanah',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Nutrisi Section
                    const Text(
                      'Nutrisi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: TextFormField(
                        controller: controller.nutrisiController,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4A4A4A),
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: InputBorder.none,
                          hintText: 'Contoh: NPK',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Asal Bibit Section
                    const Text(
                      'Asal Bibit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: TextFormField(
                        controller: controller.asalBibitController,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4A4A4A),
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: InputBorder.none,
                          hintText: 'Contoh: Pembibitan KPH',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Produktivitas Section
                    const Text(
                      'Produktivitas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: TextFormField(
                        controller: controller.produktivitasController,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4A4A4A),
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: InputBorder.none,
                          hintText: 'Contoh: Tinggi',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Lokasi Tanam (KPH)
                    const Text(
                      'Lokasi Tanam',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: controller.selectedKPH.value.isEmpty
                            ? null
                            : controller.selectedKPH.value,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          border: InputBorder.none,
                          hintText: 'Pilih KPH',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4A4A4A),
                        ),
                        items: controller.kphList.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.selectedKPH.value = value;
                            controller.loadBKPHOptions(value);
                            controller.selectedBKPH.value = '';
                            controller.selectedRKPH.value = '';
                          }
                        },
                      ),
                    ),

                    // BKPH (depends on KPH)
                    if (controller.selectedKPH.value.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: controller.selectedBKPH.value.isEmpty
                                  ? null
                                  : controller.selectedBKPH.value,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                border: InputBorder.none,
                                hintText: 'Pilih BKPH',
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF4A4A4A),
                              ),
                              items: controller.bkphOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  controller.selectedBKPH.value = value;
                                  controller.loadRKPHOptions(value);
                                  controller.selectedRKPH.value = '';
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                    // RKPH (depends on BKPH)
                    if (controller.selectedBKPH.value.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: controller.selectedRKPH.value.isEmpty
                                  ? null
                                  : controller.selectedRKPH.value,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                border: InputBorder.none,
                                hintText: 'Pilih RKPH',
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF4A4A4A),
                              ),
                              items: controller.rkphOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  controller.selectedRKPH.value = value;
                                  controller.selectedLuasPetak.value =
                                      ''; // Reset the value
                                  controller.loadLuasPetakOptions(value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
// Add this after the RKPH dropdown in the UI
// Luas Petak (depends on RKPH)
                    if (controller.selectedRKPH.value.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: controller
                                            .selectedLuasPetak.value.isEmpty ||
                                        !controller.luasPetakOptions.contains(
                                            controller.selectedLuasPetak.value)
                                    ? null // Use null if the value is empty or not in the list
                                    : controller.selectedLuasPetak.value,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  border: InputBorder.none,
                                  hintText: 'Pilih Luas Petak',
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF4A4A4A),
                                ),
                                items: controller.luasPetakOptions
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.selectedLuasPetak.value = value;
                                  }
                                },
                              )),
                        ],
                      ),
                    const SizedBox(height: 16),

                    // Tanggal Pembibitan
                    const Text(
                      'Tanggal Pembibitan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => controller.selectDate(context),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: controller.tanggalPembibitanController,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF4A4A4A),
                            ),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              border: InputBorder.none,
                              hintText: 'Pilih tanggal',
                              hintStyle: TextStyle(color: Colors.grey),
                              suffixIcon: Icon(Icons.calendar_today,
                                  color: Color(0xFF2E7D32)),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Catatan
                    const Text(
                      'Catatan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: TextFormField(
                        controller: controller.catatanController,
                        maxLines: 4,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4A4A4A),
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: InputBorder.none,
                          hintText: 'Tambahkan catatan jika perlu',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    Obx(() {
                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    controller.submitBibit(
                                        isUpdate: isEditMode);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: controller.isLoading.value
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                )
                              : Text(
                                  isEditMode
                                      ? 'SIMPAN PERUBAHAN'
                                      : 'CETAK BARCODE',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void _showImageSourceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () {
                  controller.pickImageFromCamera();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih Foto dari Galeri'),
                onTap: () {
                  controller.pickImageFromGallery();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
