import 'package:get/get.dart';
import '../../../data/repositories/intro_repository.dart';
import '../../../data/models/intro_model.dart';

class IntroController extends GetxController {
  final IntroRepository repository = IntroRepository();

  RxBool isLoading = false.obs;
  RxList<IntroModel> items = <IntroModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchItems();
  }

  Future<void> fetchItems() async {
    isLoading.value = true;
    try {
      final result = await repository.getAllIntro();
      items.assignAll(result);
    } catch (e) {
      print(e);
    } finally {
      isLoading.value = false;
    }
  }
}
