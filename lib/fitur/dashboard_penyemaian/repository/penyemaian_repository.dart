import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

import '../../dashboard_tpk/model/model_dashboard_tpk.dart';
import '../model/model_dashboard_penyemaian.dart';

class PenyemaianRepository {
  // This would typically interact with API services or local database
  // For now, we're using mock data

  Future<UserProfileModel> getUserProfile() async {
    // Simulate API call delay
    await Future.delayed(Duration(milliseconds: 500));

    // Return mock user profile
    return UserProfileModel(
      name: "Yulia Gita",
      role: "Admin Penyemaian",
      photoUrl: "", // URL to profile photo if available
    );
  }

  Future<List<ActivityModel>> getRecentActivities() async {
    // Simulate API call delay
    await Future.delayed(Duration(milliseconds: 700));

    // Return mock activities
    return [
      ActivityModel(
        icon: Icons.qr_code_scanner_rounded,
        title: "Scan Barcode Bibit Mahoni",
        time: "Baru saja",
        highlight: true,
      ),
      ActivityModel(
        icon: Icons.edit_rounded,
        title: "Pembaruan Data Bibit Jati",
        time: "2 jam yang lalu",
      ),
      ActivityModel(
        icon: Icons.print_rounded,
        title: "Pencetakan 25 Barcode",
        time: "Kemarin, 16:30",
      ),
      ActivityModel(
        icon: Icons.add_circle_outline_rounded,
        title: "Pendaftaran 30 Bibit Baru",
        time: "Kemarin, 14:15",
      ),
    ];
  }

  Future<Map<String, dynamic>> getDashboardStatistics() async {
    // Simulate API call delay
    await Future.delayed(Duration(milliseconds: 800));

    // Return mock statistics
    return {
      'totalBibit': '1,245',
      'bibitSiapTanam': '482',
      'bibitButuhPerhatian': '23',
      'bibitDipindai': '87',
      'pertumbuhanBibit': '+15%',
      'growthStatTrend': 'Bulan ini',
      'scanStatTrend': 'Minggu ini',
    };
  }

  Future<List<BibitModel>> getBibitData() async {
    // Simulate API call delay
    await Future.delayed(Duration(milliseconds: 600));

    // Return mock bibit data
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
      ),
    ];
  }
}
