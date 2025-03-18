import 'package:flutter_green_track/presentation/pages/dashboard_tpk/dashboard_tpk_page.dart';
import 'package:get/get.dart';
import '../../../data/repositories/navigation_repository.dart';
import '../../../data/models/navigation_model.dart';
import 'package:get/get.dart';

class NavigationController extends GetxController {
  // Current selected tab index
  var currentIndex = 0.obs;

  // User role to customize navigation options
  final UserRole userRole;

  NavigationController({required this.userRole});

  // Change page and update current index
  void changePage(int index) {
    currentIndex.value = index;
  }

  // Navigate to scan page
  void goToScan() {
    // This could open a modal or navigate to a dedicated scan page
    // For now, we'll just update the index
    currentIndex.value = 2; // Index 2 is reserved for scan
  }

  // Custom navigation based on user role
  void navigateToInventory() {
    currentIndex.value = 1; // Index 1 is for Inventory/Bibit depending on role
  }

  void navigateToHistory() {
    currentIndex.value = 3; // Index 3 is for History
  }

  void navigateToSettings() {
    currentIndex.value = 4; // Index 4 is for Settings
  }

  void navigateToDashboard() {
    currentIndex.value = 0; // Index 0 is for Dashboard
  }
}
