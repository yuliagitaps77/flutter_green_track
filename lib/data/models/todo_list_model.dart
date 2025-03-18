class TodoListModel {
  final int id;
  final String name;

  TodoListModel({
    required this.id,
    required this.name,
  });

  // Contoh parse JSON
  factory TodoListModel.fromJson(Map<String, dynamic> json) {
    return TodoListModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  // Contoh to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
