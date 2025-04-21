import 'package:flutter/material.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/controller/controller_page_nav_bibit.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/model/model_bibit.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditBibitPage extends StatefulWidget {
  static const String routeName = "/EditBibitPage";

  const EditBibitPage({super.key});

  @override
  State<EditBibitPage> createState() => _EditBibitPageState();
}

class _EditBibitPageState extends State<EditBibitPage> {
  final BibitController controller = Get.find();

  late Bibit bibit;

  // Controllers
  final namaController = TextEditingController();
  final varietasController = TextEditingController();
  final usiaController = TextEditingController();
  final tinggiController = TextEditingController();
  final kondisiController = TextEditingController();
  final statusHamaController = TextEditingController();
  final asalController = TextEditingController();
  final catatanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    bibit = Get.arguments as Bibit;

    // Set nilai awal
    namaController.text = bibit.namaBibit;
    varietasController.text = bibit.varietas;
    usiaController.text = bibit.usia.toString();
    tinggiController.text = bibit.tinggi.toString();
    kondisiController.text = bibit.kondisi;
    statusHamaController.text = bibit.statusHama;
    asalController.text = bibit.asalBibit;
    catatanController.text = bibit.catatan;
  }

  @override
  void dispose() {
    namaController.dispose();
    varietasController.dispose();
    usiaController.dispose();
    tinggiController.dispose();
    kondisiController.dispose();
    statusHamaController.dispose();
    asalController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  Future<void> updateBibit() async {
    try {
      final updatedData = {
        'nama_bibit': namaController.text,
        'varietas': varietasController.text,
        'usia': int.tryParse(usiaController.text) ?? 0,
        'tinggi': int.tryParse(tinggiController.text) ?? 0,
        'kondisi': kondisiController.text,
        'status_hama': statusHamaController.text,
        'asal_bibit': asalController.text,
        'catatan': catatanController.text,
        'updated_at': DateTime.now(),
      };

      await FirebaseFirestore.instance
          .collection('bibit')
          .doc(bibit.id)
          .update(updatedData);

      // Refresh controller
      await controller.fetchBibitFromFirestore();

      Get.back();
      Get.snackbar("Sukses", "Data bibit berhasil diperbarui");
    } catch (e) {
      Get.snackbar("Gagal", "Gagal update data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Bibit"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildField("Nama Bibit", namaController),
              _buildField("Varietas", varietasController),
              _buildField("Usia (hari)", usiaController, isNumber: true),
              _buildField("Tinggi (cm)", tinggiController, isNumber: true),
              _buildField("Kondisi", kondisiController),
              _buildField("Status Hama", statusHamaController),
              _buildField("Asal Bibit", asalController),
              _buildField("Catatan", catatanController, maxLines: 3),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: updateBibit,
                icon: const Icon(Icons.save),
                label: const Text("Simpan Perubahan"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
