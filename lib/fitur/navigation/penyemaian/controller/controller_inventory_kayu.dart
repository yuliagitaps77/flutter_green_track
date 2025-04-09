import 'package:get/get.dart';

class InventoryItem {
  final String id;
  final String name;
  final int quantity;

  InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
  });

  InventoryItem copyWith({
    String? id,
    String? name,
    int? quantity,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
    );
  }
}

class InventoryKayuController extends GetxController {
  // Observable list of inventory items
  final RxList<InventoryItem> inventoryItems = <InventoryItem>[].obs;

  // Observable for total wood count
  final RxInt totalWood = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize with sample data
    _loadInitialData();
    // Calculate total wood
    _calculateTotalWood();
  }

  void _loadInitialData() {
    // Sample data - in a real app, this would come from an API or database
    inventoryItems.addAll([
      InventoryItem(
        id: '1',
        name: 'Kayu Jati - Batch 1',
        quantity: 100,
      ),
      InventoryItem(
        id: '2',
        name: 'Kayu Jati - Batch 2',
        quantity: 100,
      ),
      InventoryItem(
        id: '3',
        name: 'Kayu Jati - Batch 3',
        quantity: 100,
      ),
      InventoryItem(
        id: '4',
        name: 'Kayu Jati - Batch 4',
        quantity: 100,
      ),
    ]);
  }

  void _calculateTotalWood() {
    totalWood.value =
        inventoryItems.fold(0, (sum, item) => sum + item.quantity);
  }

  // Add a new inventory item
  void addInventoryItem(String name, int quantity) {
    final newId = (inventoryItems.length + 1).toString();
    inventoryItems.add(InventoryItem(
      id: newId,
      name: name,
      quantity: quantity,
    ));
    _calculateTotalWood();
  }

  // Update an existing inventory item
  void updateInventoryItem(String id, int newQuantity) {
    final index = inventoryItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      final updatedItem = inventoryItems[index].copyWith(quantity: newQuantity);
      inventoryItems[index] = updatedItem;
      _calculateTotalWood();
    }
  }

  // Delete an inventory item
  void deleteInventoryItem(String id) {
    inventoryItems.removeWhere((item) => item.id == id);
    _calculateTotalWood();
  }

  // Get a single inventory item by ID
  InventoryItem? getInventoryItem(String id) {
    try {
      return inventoryItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }
}
