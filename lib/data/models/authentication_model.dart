class AuthenticationModel {
  final int id;
  final String name;

  AuthenticationModel({
    required this.id,
    required this.name,
  });

  // Contoh parse JSON
  factory AuthenticationModel.fromJson(Map<String, dynamic> json) {
    return AuthenticationModel(
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
