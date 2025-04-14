import 'package:flutter/material.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/model/model_dashboard_tpk.dart';

class DashboardTpkRepository {
  // This would typically interact with API services or local database
  // For now, we're using mock data

  Future<UserProfileModel> getUserProfile() async {
    // Simulate API call delay
    await Future.delayed(Duration(milliseconds: 500));

    // Return mock user profile
    return UserProfileModel(
      name: "Fitri Meydayani",
      role: "Admin TPK",
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
        title: "Scan Barcode Kayu Jati",
        time: "Baru saja",
        highlight: true,
      ),
      ActivityModel(
        icon: Icons.inventory_2_rounded,
        title: "Update Stok Kayu",
        time: "Kemarin, 16:30",
      ),
      ActivityModel(
        icon: Icons.assignment_rounded,
        title: "Laporan Bulanan Dibuat",
        time: "Kemarin, 14:15",
      ),
    ];
  }

  Future<Map<String, dynamic>> getDashboardStatistics() async {
    // Simulate API call delay
    await Future.delayed(Duration(milliseconds: 800));

    // Return mock statistics
    return {
      'totalWood': '876',
      'scannedWood': '87',
      'woodStatTrend': 'Minggu ini',
      'scanStatTrend': 'Bulan ini',
    };
  }

  Future<List<InventoryModel>> getInventoryData() async {
    // Simulate API call delay
    await Future.delayed(Duration(milliseconds: 600));

    // Return mock inventory data
    return [
      InventoryModel(
        woodType: "Kayu Jati",
        quantity: 534,
        lastUpdated: "2023-04-12",
      ),
      InventoryModel(
        woodType: "Kayu Mahoni",
        quantity: 342,
        lastUpdated: "2023-04-10",
      ),
    ];
  }
}
