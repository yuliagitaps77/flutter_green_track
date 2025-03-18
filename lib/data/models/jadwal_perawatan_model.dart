class JadwalPerawatanModel {
  final int id;
  final String name;

  JadwalPerawatanModel({
    required this.id,
    required this.name,
  });

  // Contoh parse JSON
  factory JadwalPerawatanModel.fromJson(Map<String, dynamic> json) {
    return JadwalPerawatanModel(
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
