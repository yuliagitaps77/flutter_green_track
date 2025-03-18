class DashboardTpkModel {
  final int id;
  final String name;

  DashboardTpkModel({
    required this.id,
    required this.name,
  });

  // Contoh parse JSON
  factory DashboardTpkModel.fromJson(Map<String, dynamic> json) {
    return DashboardTpkModel(
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
