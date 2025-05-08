import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';
import 'package:flutter_green_track/controllers/dashboard_tpk/controller_inventory_kayu.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/detail_bibit.dart';
import 'package:get/get.dart';

// PART 3: Enhanced UI for the Inventory Page
class InventoryKayuPage extends StatefulWidget {
  static String routeName = "/inventoryKayu";
  const InventoryKayuPage({Key? key}) : super(key: key);

  @override
  State<InventoryKayuPage> createState() => _InventoryKayuPageState();
}

class _InventoryKayuPageState extends State<InventoryKayuPage> {
  final InventoryKayuController controller = Get.put(InventoryKayuController());
  final searchController = TextEditingController();
  final RxBool isSearching = false.obs;
  final RxString searchQuery = ''.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => isSearching.value
            ? TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Cari inventory...',
                  hintStyle: TextStyle(color: Colors.green.withOpacity(0.5)),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.green),
                onChanged: (value) => searchQuery.value = value,
                autofocus: true,
              )
            : const Text('Green Track',
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.green),
          onPressed: () {},
        ),
        actions: [
          // Search toggle button
          IconButton(
            icon: Obx(() => Icon(isSearching.value ? Icons.close : Icons.search,
                color: Colors.green)),
            onPressed: () {
              isSearching.value = !isSearching.value;
              if (!isSearching.value) {
                searchController.clear();
                searchQuery.value = '';
              }
            },
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green),
            onPressed: () => controller.refreshInventory(),
          ),
          // User profile button
          IconButton(
            icon: const Icon(Icons.person, color: Colors.green),
            onPressed: () {},
          ),
        ],
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Inventory Kayu',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  Obx(() => controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        )
                      : const SizedBox()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2,
                              size: 32, color: Colors.green),
                          const SizedBox(height: 8),
                          const Text('Total Kayu',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey)),
                          Obx(() => Text(
                                controller.totalKayu.value.toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              )),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.layers,
                              size: 32, color: Colors.green),
                          const SizedBox(height: 8),
                          const Text('Jumlah Batch',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey)),
                          Obx(() => Text(
                                controller.jumlahBatch.value.toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Inventory',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  // Optional: Add filter options here
                ],
              ),
              const SizedBox(height: 8),

              // Error message if any
              Obx(() => controller.errorMessage.value.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.errorMessage.value,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.red),
                            onPressed: () => controller.refreshInventory(),
                            iconSize: 16,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox()),

              // Main content - inventory list with filtering
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                          SizedBox(height: 16),
                          Text("Memuat data inventory...",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  } else if (controller.inventoryItems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            "Belum ada data inventory",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Tambahkan persediaan kayu baru",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Filter items based on search query
                    final items = controller.inventoryItems.where((item) {
                      if (searchQuery.value.isEmpty) return true;

                      final query = searchQuery.value.toLowerCase();
                      return item.batch.toLowerCase().contains(query) ||
                          item.namaKayu.toLowerCase().contains(query) ||
                          item.jenisKayu.toLowerCase().contains(query);
                    }).toList();

                    if (items.isEmpty) {
                      // No items match search
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              "Tidak ada hasil untuk '${searchQuery.value}'",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                        onRefresh: () =>
                            controller.fetchInventoryFromFirestore(),
                        color: Colors.green,
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 1,
                              child: InkWell(
                                // Ubah onTap untuk navigasi ke KayuDetailPage alih-alih dialog
                                onTap: () {
                                  print(
                                      '🔥 [ITEM CLICK] Navigasi ke halaman detail: ${item.id}');
                                  // Langsung akses dan gunakan userRole yang ada di controller
                                  UserRole? userRole;
                                  // Cek apakah userRole tersedia di scope tertentu, sesuaikan dengan struktur app Anda
                                  if (controller is InventoryKayuController) {
                                    // Asumsi controller memiliki akses ke userRole
                                    // Atau gunakan cara lain untuk mendapatkan userRole sesuai dengan struktur aplikasi Anda
                                    userRole = UserRole
                                        .adminTPK; // Ini contoh default, sesuaikan dengan kebutuhan
                                  }

                                  Get.to(() => KayuDetailPage(
                                        kayuId: item.id,
                                        userRole: userRole,
                                      ));
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: ListTile(
                                    // Display an image if available
                                    leading: item.imageUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              item.imageUrl,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  width: 50,
                                                  height: 50,
                                                  color: Colors.grey
                                                      .withOpacity(0.2),
                                                  child: const Icon(
                                                      Icons.image_not_supported,
                                                      color: Colors.grey),
                                                );
                                              },
                                            ),
                                          )
                                        : Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.green.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.forest,
                                                color: Colors.green),
                                          ),
                                    title: Text(
                                      item.batch,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Jumlah Stok: ${item.stock}'),
                                        if (item.namaKayu.isNotEmpty)
                                          Text(
                                            item.namaKayu,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Icon button untuk langsung ke halaman detail
                                        IconButton(
                                          icon: const Icon(Icons.info_outline,
                                              color: Colors.blue),
                                          onPressed: () {
                                            UserRole? userRole;
                                            if (controller
                                                is InventoryKayuController) {
                                              userRole = UserRole
                                                  .adminTPK; // Sesuaikan dengan kebutuhan
                                            }

                                            Get.to(() => KayuDetailPage(
                                                  kayuId: item.id,
                                                  userRole: userRole,
                                                ));
                                          },
                                        ),
                                        // Edit button
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.green),
                                          onPressed: () => controller.editItem(
                                              controller.inventoryItems
                                                  .indexOf(item)),
                                        ),
                                        // Delete button
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.green),
                                          onPressed: () =>
                                              controller.deleteItem(controller
                                                  .inventoryItems
                                                  .indexOf(item)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ));
                  }
                }),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => controller.addNewInventory(),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambahkan Persediaan baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
