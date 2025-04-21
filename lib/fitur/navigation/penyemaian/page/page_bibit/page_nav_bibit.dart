import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/controller/controller_page_nav_bibit.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/model/model_bibit.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/page/page_bibit/page_detail_bibit.dart';

class DaftarBibitPage extends StatefulWidget {
  static String routeName = "/daftar-bibit";

  const DaftarBibitPage({Key? key}) : super(key: key);

  @override
  State<DaftarBibitPage> createState() => _DaftarBibitPageState();
}

class _DaftarBibitPageState extends State<DaftarBibitPage> {
  final BibitController controller = Get.put(BibitController());

  final List<String> jenisList = [
    'Semua',
    'Jati',
    'Mahoni',
    'Trembesi',
    'Sengon'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Bibit',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
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
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) => controller.filterBibit(value),
                    decoration: const InputDecoration(
                      hintText: 'Cari bibit...',
                      prefixIcon: Icon(Icons.search, color: Colors.green),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Jenis filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Obx(() => Row(
                        children: [
                          _buildJenisChip(
                              'Semua', controller.selectedJenis == 'Semua'),
                          ...controller.jenisList
                              .map((jenis) => _buildJenisChip(
                                    jenis,
                                    controller.selectedJenis == jenis,
                                  )),
                        ],
                      )),
                ),
                const SizedBox(height: 20),
                // Grid view of bibit
                Expanded(
                  child: Obx(
                    () => controller.filteredBibitList.isEmpty
                        ? const Center(child: Text('Tidak ada data bibit'))
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: controller.filteredBibitList.length,
                            itemBuilder: (context, index) {
                              final bibit = controller.filteredBibitList[index];
                              return _buildBibitCard(bibit);
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJenisChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.green,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (_) {
          controller.filterByJenis(label);
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.green,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.green.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildBibitCard(Bibit bibit) {
    return GestureDetector(
      onTap: () => Get.toNamed(BibitDetailPage.routeName, arguments: bibit),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.green.withOpacity(0.1),
                child: bibit.gambarImage.isNotEmpty
                    ? Image.network(
                        bibit.gambarImage.first,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.park, size: 50, color: Colors.green),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bibit.namaBibit,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bibit.jenisBibit,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.height, size: 14, color: Colors.brown),
                      const SizedBox(width: 4),
                      Text('${bibit.tinggi} cm',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text('${bibit.usia} hari',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
