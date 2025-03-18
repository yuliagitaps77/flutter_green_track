import 'package:get/get.dart';
import '../../../data/repositories/authentication_repository.dart';
import '../../../data/models/authentication_model.dart';

class AuthenticationController extends GetxController {
  final AuthenticationRepository repository = AuthenticationRepository();

  RxBool isLoading = false.obs;
  RxList<AuthenticationModel> items = <AuthenticationModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchItems();
  }

  Future<void> fetchItems() async {
    isLoading.value = true;
    try {
      final result = await repository.getAllAuthentication();
      items.assignAll(result);
    } catch (e) {
      print(e);
    } finally {
      isLoading.value = false;
    }
  }
}
