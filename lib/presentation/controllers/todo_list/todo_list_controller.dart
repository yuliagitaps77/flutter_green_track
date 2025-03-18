import 'package:get/get.dart';
import '../../../data/repositories/todo_list_repository.dart';
import '../../../data/models/todo_list_model.dart';

class TodoListController extends GetxController {
  final TodoListRepository repository = TodoListRepository();

  RxBool isLoading = false.obs;
  RxList<TodoListModel> items = <TodoListModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchItems();
  }

  Future<void> fetchItems() async {
    isLoading.value = true;
    try {
      final result = await repository.getAllTodoList();
      items.assignAll(result);
    } catch (e) {
      print(e);
    } finally {
      isLoading.value = false;
    }
  }
}
