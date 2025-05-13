import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/dashboard_tpk/tambah_persedian_kayu_controller.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class TambahPersediaanKayuPage extends StatefulWidget {
  static String routeName = "/tambahPersediaanKayu";

  const TambahPersediaanKayuPage({Key? key}) : super(key: key);

  @override
  State<TambahPersediaanKayuPage> createState() =>
      _TambahPersediaanKayuPageState();
}

class _TambahPersediaanKayuPageState extends State<TambahPersediaanKayuPage> {
  final TambahPersediaanController controller =
      Get.put(TambahPersediaanController());

  void _showImageSourceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: Color(0xFF4CAF50)),
                title: Text(
                  'Ambil Foto dari Kamera',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF424242),
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  controller.pickImageFromCamera();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFF4CAF50)),
                title: Text(
                  'Pilih Foto dari Galeri',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF424242),
                    fontSize: 16,
                  ),
                ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tambah Persediaan Kayu',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
          onPressed: () => Get.back(),
        ),
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
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Upload Section
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Color(0xFF4CAF50),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Obx(() => controller.selectedImages.isEmpty
                        ? Icon(Icons.forest_rounded,
                            size: 100, color: Color(0xFF4CAF50))
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(
                              File(controller.selectedImages.first),
                              fit: BoxFit.cover,
                            ),
                          )),
                  ),
                ),
                Obx(() => controller.selectedImages.isNotEmpty
                    ? Column(
                        children: [
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 120,
                            child: ReorderableListView(
                              scrollDirection: Axis.horizontal,
                              onReorder: (oldIndex, newIndex) {
                                // Reorder the images list
                                final image = controller.selectedImages
                                    .removeAt(oldIndex);
                                controller.selectedImages
                                    .insert(newIndex, image);

                                // If the reordered image is now at index 0, it becomes the main image
                                if (newIndex == 0) {
                                  controller.updateSelectedImage();
                                }
                              },
                              children: List.generate(
                                  controller.selectedImages.length, (index) {
                                return Padding(
                                  key: Key(controller.selectedImages[index]),
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(
                                              controller.selectedImages[index]),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: -8,
                                        right: -8,
                                        child: GestureDetector(
                                          onTap: () {
                                            controller.removeImage(index);
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
                      )
                    : const SizedBox.shrink()),
// Add Image Button (circle with plus sign)
                SizedBox(
                  height: 20,
                ),
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
                          color: Colors.green,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                // Form Fields
                _buildFormField(
                  controller: controller.idController,
                  label: 'ID Kayu (otomatis)',
                  enabled: false,
                  fillColor: Color(0xFFF5F9F5),
                ),

                _buildFormField(
                  controller: controller.namaController,
                  label: 'Nama Kayu',
                  hint: 'Contoh: Meranti',
                ),

                _buildFormField(
                  controller: controller.varietasController,
                  label: 'Varietas',
                  hint: 'Contoh: Hutan rimba',
                ),

                _buildFormField(
                  controller: controller.usiaController,
                  label: 'Usia',
                  hint: 'Dalam bulan/tahun',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  suffixText: 'bulan',
                ),

                _buildFormField(
                  controller: controller.tinggiController,
                  label: 'Tinggi',
                  hint: 'Dalam meter',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                  ],
                  suffixText: 'meter',
                ),

                _buildFormField(
                  controller: controller.jenisController,
                  label: 'Jenis Kayu',
                  hint: 'Pilihan: Cengkeh, Jati, dll',
                ),

                _buildFormField(
                  controller: controller.jumlahStokController,
                  label: 'Jumlah Stok',
                  hint: 'Catatan: berdasarkan unit',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  suffixText: 'unit',
                ),

                _buildFormField(
                  controller: controller.tanggalController,
                  label: 'Tanggal',
                  hint: 'DD/MM/YYYY',
                  readOnly: true,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today, color: Color(0xFF4CAF50)),
                    onPressed: () => controller.pickDate(context),
                  ),
                  onTap: () => controller.pickDate(context),
                ),

                _buildFormField(
                  controller: controller.batchPanenController,
                  label: 'Batch Panen',
                  hint: 'Contoh: 1_2022',
                ),

                _buildFormField(
                  controller: controller.catatanController,
                  label: 'Catatan',
                  hint: 'Tambahkan catatan jika perlu',
                  maxLines: 4,
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : () => controller.saveInventory(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: controller.isLoading.value
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Text(
                                'Tambah',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                      )),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool enabled = true,
    bool readOnly = false,
    Color? fillColor,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? suffixText,
    Widget? suffixIcon,
    int? maxLines,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        readOnly: readOnly,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines ?? 1,
        onTap: onTap,
        style: TextStyle(
          fontFamily: 'Poppins',
          color: Color(0xFF424242),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF2E7D32),
            fontSize: 16,
          ),
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.grey[400],
            fontSize: 14,
          ),
          filled: true,
          fillColor: fillColor ?? Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Color(0xFF4CAF50)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Color(0xFF4CAF50)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixText: suffixText,
          suffixStyle: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF424242),
            fontSize: 14,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
