import 'package:flutter/material.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/model/model_bibit.dart';
import 'package:get/get.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class BibitController extends GetxController {
  final RxList<Bibit> _bibitList = <Bibit>[].obs;
  final RxList<Bibit> _filteredBibitList = <Bibit>[].obs;
  final RxString _selectedJenis = 'Semua'.obs;
  final RxString _searchQuery = ''.obs;
  var jenisList = <String>[].obs;
  Future<void> fetchJenisList() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('bibit').get();

      final allJenis = snapshot.docs
          .map((doc) => doc['jenis_bibit']?.toString() ?? '')
          .where((jenis) => jenis.isNotEmpty)
          .toSet()
          .toList();

      jenisList.assignAll(allJenis);
    } catch (e) {
      print('Gagal mengambil jenis bibit: $e');
    }
  }

  // Getters
  List<Bibit> get bibitList => _bibitList;
  List<Bibit> get filteredBibitList => _filteredBibitList;
  String get selectedJenis => _selectedJenis.value;
  String get searchQuery => _searchQuery.value;

  @override
  void onInit() {
    super.onInit();
    fetchBibitFromFirestore();
    fetchJenisList(); // ambil semua jenis unik dari Firestore
  }

  /// Fetch data dari Firestore
  Future<void> fetchBibitFromFirestore() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('bibit').get();
      final result =
          snapshot.docs.map((doc) => Bibit.fromFirestore(doc)).toList();

      _bibitList.assignAll(result);
      _applyFilters();
    } catch (e) {
      print('Gagal mengambil data bibit: $e');
    }
  }

  // Filter berdasarkan teks pencarian
  void filterBibit(String query) {
    _searchQuery.value = query;
    _applyFilters();
  }

  // Filter berdasarkan jenis bibit
  void filterByJenis(String jenis) {
    _selectedJenis.value = jenis;
    _applyFilters();
  }

  // Terapkan kombinasi filter
  void _applyFilters() {
    _filteredBibitList.assignAll(_bibitList.where((bibit) {
      final matchJenis = _selectedJenis.value == 'Semua' ||
          bibit.jenisBibit == _selectedJenis.value;
      final matchSearch = _searchQuery.value.isEmpty ||
          bibit.namaBibit
              .toLowerCase()
              .contains(_searchQuery.value.toLowerCase());

      return matchJenis && matchSearch;
    }).toList());
  }

  // Ambil bibit berdasarkan ID
  Bibit? getBibitById(String id) {
    try {
      return _bibitList.firstWhere((bibit) => bibit.id == id);
    } catch (_) {
      return null;
    }
  }

  // Tambah bibit ke list (opsional jika kamu insert manual)
  void tambahBibit(Bibit bibit) {
    _bibitList.add(bibit);
    _applyFilters();
  }

  // Update data bibit
  void updateBibit(Bibit updatedBibit) {
    final index = _bibitList.indexWhere((bibit) => bibit.id == updatedBibit.id);
    if (index != -1) {
      _bibitList[index] = updatedBibit;
      _applyFilters();
    }
  }

  Future<void> hapusBibitFromDatabase(String id) async {
    try {
      // Hapus dari Firestore
      await FirebaseFirestore.instance.collection('bibit').doc(id).delete();

      // Hapus dari list lokal
      _bibitList.removeWhere((bibit) => bibit.id == id);
      _applyFilters();

      print("✅ Bibit berhasil dihapus: $id");
    } catch (e) {
      print("❌ Gagal menghapus bibit: $e");
      rethrow;
    }
  }
}
