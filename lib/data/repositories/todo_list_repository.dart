import '../models/todo_list_model.dart';
import '../services/todo_list_service.dart';

class TodoListRepository {
  final TodoListService service = TodoListService();

  Future<List<TodoListModel>> getAllTodoList() async {
    final data = await service.fetchTodoListData();
    return data.map((json) => TodoListModel.fromJson(json)).toList();
  }
}
