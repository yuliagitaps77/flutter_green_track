import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Bibit {
  final String id;
  final String namaBibit;
  final String varietas;
  final int usia;
  final int tinggi;
  final String jenisBibit;
  final String kondisi;
  final String statusHama;
  final String mediaTanam;
  final String nutrisi;
  final String asalBibit;
  final String produktivitas;
  final String catatan;
  final List<String> gambarImage;
  final String urlBibit;
  final String kph;
  final String bkph;
  final String rkph;
  final DateTime createdAt;
  final DateTime tanggalPembibitan;
  final DateTime updatedAt;

  Bibit({
    required this.id,
    required this.namaBibit,
    required this.varietas,
    required this.usia,
    required this.tinggi,
    required this.jenisBibit,
    required this.kondisi,
    required this.statusHama,
    required this.mediaTanam,
    required this.nutrisi,
    required this.asalBibit,
    required this.produktivitas,
    required this.catatan,
    required this.gambarImage,
    required this.urlBibit,
    required this.kph,
    required this.bkph,
    required this.rkph,
    required this.createdAt,
    required this.tanggalPembibitan,
    required this.updatedAt,
  });

  factory Bibit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    try {
      print("Parsing Bibit ID: ${doc.id}");
      print(
          "nama_bibit: ${data['nama_bibit']} (${data['nama_bibit'].runtimeType})");
      print("varietas: ${data['varietas']} (${data['varietas'].runtimeType})");
      print(
          "asal_bibit: ${data['asal_bibit']} (${data['asal_bibit'].runtimeType})");
      print("catatan: ${data['catatan']} (${data['catatan'].runtimeType})");
      print("tinggi: ${data['tinggi']} (${data['tinggi'].runtimeType})");
      print("usia: ${data['usia']} (${data['usia'].runtimeType})");
      // Tambahkan lagi jika perlu

      return Bibit(
        id: doc.id,
        namaBibit: data['nama_bibit']?.toString() ?? '',
        varietas: data['varietas']?.toString() ?? '',
        usia: (data['usia'] ?? 0).toDouble().toInt(),
        tinggi: (data['tinggi'] ?? 0).toDouble().toInt(),
        jenisBibit: data['jenis_bibit']?.toString() ?? '',
        kondisi: data['kondisi']?.toString() ?? '',
        statusHama: data['status_hama']?.toString() ?? '',
        mediaTanam: data['media_tanam']?.toString() ?? '',
        nutrisi: data['nutrisi']?.toString() ?? '',
        asalBibit: data['asal_bibit']?.toString() ?? '',
        produktivitas: data['produktivitas']?.toString() ?? '',
        catatan: data['catatan']?.toString() ?? '',
        gambarImage: List<String>.from(data['gambar_image'] ?? []),
        urlBibit: data['url_bibit']?.toString() ?? '',
        kph: data['lokasi_tanam']?['kph']?.toString() ?? '',
        bkph: data['lokasi_tanam']?['bkph']?.toString() ?? '',
        rkph: data['lokasi_tanam']?['rkph']?.toString() ?? '',
        createdAt:
            (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        tanggalPembibitan:
            (data['tanggal_pembibitan'] as Timestamp?)?.toDate() ??
                DateTime.now(),
        updatedAt:
            (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      print("❌ Error parsing bibit [${doc.id}]: $e");
      rethrow;
    }
  }
}
