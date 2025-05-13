import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';
import 'package:flutter_green_track/controllers/dashboard_tpk/controller_inventory_kayu.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/detail_bibit.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/widget/widget_dashboard.dart';
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
        title: const Text(
          'Jadwal Perawatan',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF4CAF50)),
                          ),
                        )
                      : const SizedBox()),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2,
                              size: 32, color: Color(0xFF4CAF50)),
                          const SizedBox(height: 10),
                          const Text('Total Kayu',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF424242),
                                fontFamily: 'Poppins',
                              )),
                          Obx(() => Text(
                                controller.totalKayu.value.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Color(0xFF2E7D32),
                                  fontFamily: 'Poppins',
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 10),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.layers,
                              size: 32, color: Color(0xFF4CAF50)),
                          const SizedBox(height: 10),
                          const Text('Jumlah Batch',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF424242),
                                fontFamily: 'Poppins',
                              )),
                          Obx(() => Text(
                                controller.jumlahBatch.value.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Color(0xFF2E7D32),
                                  fontFamily: 'Poppins',
                                ),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

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
                        color: Color(0xFF4CAF50),
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 2,
                              child: InkWell(
                                onTap: () {
                                  print(
                                      '🔥 [ITEM CLICK] Navigasi ke halaman detail: ${item.id}');
                                  UserRole? userRole;
                                  if (controller is InventoryKayuController) {
                                    userRole = UserRole.adminTPK;
                                  }

                                  Get.to(() => KayuDetailPage(
                                        kayuId: item.id,
                                        userRole: userRole,
                                      ));
                                },
                                borderRadius: BorderRadius.circular(15),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: ListTile(
                                    leading: item.imageUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
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
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFFF5F9F5),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: const Icon(
                                                      Icons.image_not_supported,
                                                      color: Color(0xFF4CAF50)),
                                                );
                                              },
                                            ),
                                          )
                                        : Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: Color(0xFFF5F9F5),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(Icons.forest,
                                                color: Color(0xFF4CAF50)),
                                          ),
                                    title: Text(
                                      item.batch,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Color(0xFF2E7D32),
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Jumlah Stok: ${item.stock}',
                                          style: const TextStyle(
                                            color: Color(0xFF424242),
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        if (item.namaKayu.isNotEmpty)
                                          Text(
                                            item.namaKayu,
                                            style: const TextStyle(
                                              color: Color(0xFF424242),
                                              fontSize: 12,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.info_outline,
                                              color: Color(0xFF4CAF50)),
                                          onPressed: () {
                                            UserRole? userRole;
                                            if (controller
                                                is InventoryKayuController) {
                                              userRole = UserRole.adminTPK;
                                            }

                                            Get.to(() => KayuDetailPage(
                                                  kayuId: item.id,
                                                  userRole: userRole,
                                                ));
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Color(0xFF4CAF50)),
                                          onPressed: () => controller.editItem(
                                              controller.inventoryItems
                                                  .indexOf(item)),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Color(0xFF4CAF50)),
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
                  label: const Text(
                    'Tambahkan Persediaan baru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
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
