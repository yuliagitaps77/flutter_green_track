import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/todo_list/todo_list_controller.dart';

class TodoListPage extends GetView<TodoListController> {
  const TodoListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Daftarkan controller di sini, kalau mau lazyPut, dsb.
    Get.put(TodoListController());
    
    return Scaffold(
      appBar: AppBar(
        title: Text('TodoList Page'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.items.isEmpty) {
          return const Center(child: Text('No data.'));
        }
        return ListView.builder(
          itemCount: controller.items.length,
          itemBuilder: (context, index) {
            final item = controller.items[index];
            return ListTile(
              title: Text(item.name),
            );
          },
        );
      }),
    );
  }
}
