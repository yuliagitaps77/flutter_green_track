class IntroModel {
  final int id;
  final String name;

  IntroModel({
    required this.id,
    required this.name,
  });

  // Contoh parse JSON
  factory IntroModel.fromJson(Map<String, dynamic> json) {
    return IntroModel(
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
