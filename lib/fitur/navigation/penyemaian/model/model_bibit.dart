import 'package:flutter/material.dart';

class Bibit {
  final String id;
  final String nama;
  final String kategori;
  final IconData icon;
  final String kebutuhanAir;
  final String kebutuhanSinar;
  final String suhuIdeal;
  final int masaPanen;
  final String deskripsi;
  final List<String> langkahPenanaman;
  final List<String> manfaat;

  Bibit({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.icon,
    required this.kebutuhanAir,
    required this.kebutuhanSinar,
    required this.suhuIdeal,
    required this.masaPanen,
    required this.deskripsi,
    required this.langkahPenanaman,
    required this.manfaat,
  });

  // Method untuk membuat clone dari objek Bibit dengan properti yang diperbarui
  Bibit copyWith({
    String? id,
    String? nama,
    String? kategori,
    IconData? icon,
    String? kebutuhanAir,
    String? kebutuhanSinar,
    String? suhuIdeal,
    int? masaPanen,
    String? deskripsi,
    List<String>? langkahPenanaman,
    List<String>? manfaat,
  }) {
    return Bibit(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      kategori: kategori ?? this.kategori,
      icon: icon ?? this.icon,
      kebutuhanAir: kebutuhanAir ?? this.kebutuhanAir,
      kebutuhanSinar: kebutuhanSinar ?? this.kebutuhanSinar,
      suhuIdeal: suhuIdeal ?? this.suhuIdeal,
      masaPanen: masaPanen ?? this.masaPanen,
      deskripsi: deskripsi ?? this.deskripsi,
      langkahPenanaman: langkahPenanaman ?? this.langkahPenanaman,
      manfaat: manfaat ?? this.manfaat,
    );
  }

  // Method untuk konversi dari JSON ke objek Bibit
  factory Bibit.fromJson(Map<String, dynamic> json) {
    return Bibit(
      id: json['id'],
      nama: json['nama'],
      kategori: json['kategori'],
      icon: IconData(json['iconCode'], fontFamily: 'MaterialIcons'),
      kebutuhanAir: json['kebutuhanAir'],
      kebutuhanSinar: json['kebutuhanSinar'],
      suhuIdeal: json['suhuIdeal'],
      masaPanen: json['masaPanen'],
      deskripsi: json['deskripsi'],
      langkahPenanaman: List<String>.from(json['langkahPenanaman']),
      manfaat: List<String>.from(json['manfaat']),
    );
  }

  // Method untuk konversi dari objek Bibit ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'kategori': kategori,
      'iconCode': icon.codePoint,
      'kebutuhanAir': kebutuhanAir,
      'kebutuhanSinar': kebutuhanSinar,
      'suhuIdeal': suhuIdeal,
      'masaPanen': masaPanen,
      'deskripsi': deskripsi,
      'langkahPenanaman': langkahPenanaman,
      'manfaat': manfaat,
    };
  }
}
