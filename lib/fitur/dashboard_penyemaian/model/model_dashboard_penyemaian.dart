import 'package:flutter/material.dart';

class BibitModel {
  final String id;
  final String jenisBibit;
  final String umur;
  final double tinggi;
  final String kondisi;
  final String tanggalTanam;
  final String lokasi;
  final bool siapTanam;
  final bool butuhPerhatian;
  final IconData icon;
  final DateTime lastUpdated;

  // Optional fields for additional data that might be needed by controller
  final int? jumlahPenyiraman;
  final int? jumlahPemupukan;
  final String? catatan;
  final String? fotoUrl;

  BibitModel({
    required this.id,
    required this.jenisBibit,
    required this.umur,
    required this.tinggi,
    required this.kondisi,
    required this.tanggalTanam,
    required this.lokasi,
    this.siapTanam = false,
    this.butuhPerhatian = false,
    this.icon = Icons.forest_rounded,
    DateTime? lastUpdated,
    this.jumlahPenyiraman,
    this.jumlahPemupukan,
    this.catatan,
    this.fotoUrl,
  }) : this.lastUpdated = lastUpdated ?? DateTime.now();

  // Add getter for nama_bibit to fix the error
  String get nama_bibit => jenisBibit;

  // Format the height as a string with cm unit
  String get tinggiFormatted => "${tinggi.toStringAsFixed(1)} cm";

  // Calculate the age in days from tanggalTanam
  int get usiaBibitDays {
    try {
      final plantDate = DateTime.parse(tanggalTanam);
      return DateTime.now().difference(plantDate).inDays;
    } catch (e) {
      return 0;
    }
  }

  // Get a color based on the condition
  Color get kondisiColor {
    switch (kondisi.toLowerCase()) {
      case 'baik':
        return Colors.green;
      case 'butuh perawatan':
        return Colors.orange;
      case 'sakit':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  // Convert BibitModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jenisBibit': jenisBibit,
      'umur': umur,
      'tinggi': tinggi,
      'kondisi': kondisi,
      'tanggalTanam': tanggalTanam,
      'lokasi': lokasi,
      'siapTanam': siapTanam,
      'butuhPerhatian': butuhPerhatian,
      'lastUpdated': lastUpdated.toIso8601String(),
      'jumlahPenyiraman': jumlahPenyiraman,
      'jumlahPemupukan': jumlahPemupukan,
      'catatan': catatan,
      'fotoUrl': fotoUrl,
    };
  }

  // Create BibitModel from JSON
  factory BibitModel.fromJson(Map<String, dynamic> json) {
    return BibitModel(
      id: json['id'] ?? '',
      jenisBibit: json['jenisBibit'] ?? '',
      umur: json['umur'] ?? '',
      tinggi: (json['tinggi'] is int)
          ? (json['tinggi'] as int).toDouble()
          : (json['tinggi'] ?? 0.0) as double,
      kondisi: json['kondisi'] ?? '',
      tanggalTanam: json['tanggalTanam'] ?? '',
      lokasi: json['lokasi'] ?? '',
      siapTanam: json['siapTanam'] ?? false,
      butuhPerhatian: json['butuhPerhatian'] ?? false,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
      jumlahPenyiraman: json['jumlahPenyiraman'],
      jumlahPemupukan: json['jumlahPemupukan'],
      catatan: json['catatan'],
      fotoUrl: json['fotoUrl'],
    );
  }

  // Create a copy of BibitModel with updated fields
  BibitModel copyWith({
    String? id,
    String? jenisBibit,
    String? umur,
    double? tinggi,
    String? kondisi,
    String? tanggalTanam,
    String? lokasi,
    bool? siapTanam,
    bool? butuhPerhatian,
    IconData? icon,
    DateTime? lastUpdated,
    int? jumlahPenyiraman,
    int? jumlahPemupukan,
    String? catatan,
    String? fotoUrl,
  }) {
    return BibitModel(
      id: id ?? this.id,
      jenisBibit: jenisBibit ?? this.jenisBibit,
      umur: umur ?? this.umur,
      tinggi: tinggi ?? this.tinggi,
      kondisi: kondisi ?? this.kondisi,
      tanggalTanam: tanggalTanam ?? this.tanggalTanam,
      lokasi: lokasi ?? this.lokasi,
      siapTanam: siapTanam ?? this.siapTanam,
      butuhPerhatian: butuhPerhatian ?? this.butuhPerhatian,
      icon: icon ?? this.icon,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      jumlahPenyiraman: jumlahPenyiraman ?? this.jumlahPenyiraman,
      jumlahPemupukan: jumlahPemupukan ?? this.jumlahPemupukan,
      catatan: catatan ?? this.catatan,
      fotoUrl: fotoUrl ?? this.fotoUrl,
    );
  }

  // Create a list of dummy BibitModel for testing
  static List<BibitModel> getDummyData() {
    return [
      BibitModel(
        id: "BIB001",
        jenisBibit: "Mahoni",
        umur: "3 bulan",
        tinggi: 45.5,
        kondisi: "Baik",
        tanggalTanam: "2023-01-15",
        lokasi: "Blok A-1",
        siapTanam: true,
        butuhPerhatian: false,
        catatan: "Pertumbuhan baik, siap dipindahkan",
      ),
      BibitModel(
        id: "BIB002",
        jenisBibit: "Jati",
        umur: "2 bulan",
        tinggi: 30.2,
        kondisi: "Baik",
        tanggalTanam: "2023-02-10",
        lokasi: "Blok A-2",
        siapTanam: false,
        butuhPerhatian: false,
        jumlahPenyiraman: 24,
      ),
      BibitModel(
        id: "BIB003",
        jenisBibit: "Trembesi",
        umur: "4 bulan",
        tinggi: 60.0,
        kondisi: "Butuh Perawatan",
        tanggalTanam: "2023-01-05",
        lokasi: "Blok B-3",
        siapTanam: false,
        butuhPerhatian: true,
        catatan: "Daun menguning, perlu pemupukan tambahan",
        jumlahPemupukan: 2,
      ),
    ];
  }
}
