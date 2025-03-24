import 'package:get/get.dart';
import '../../data/repositories/jadwal_perawatan_repository.dart';
import '../../data/models/jadwal_perawatan_model.dart';

class JadwalPerawatanController extends GetxController {
  final JadwalPerawatanRepository repository = JadwalPerawatanRepository();

  RxBool isLoading = false.obs;
  RxList<JadwalPerawatanModel> items = <JadwalPerawatanModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchItems();
  }

  Future<void> fetchItems() async {
    isLoading.value = true;
    try {
      final result = await repository.getAllJadwalPerawatan();
      items.assignAll(result);
    } catch (e) {
      print(e);
    } finally {
      isLoading.value = false;
    }
  }
}
