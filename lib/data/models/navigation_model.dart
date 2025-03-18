class NavigationModel {
  final int id;
  final String name;

  NavigationModel({
    required this.id,
    required this.name,
  });

  // Contoh parse JSON
  factory NavigationModel.fromJson(Map<String, dynamic> json) {
    return NavigationModel(
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
