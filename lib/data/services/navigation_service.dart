class NavigationService {
  // Misal: method untuk fetch data dari API atau database
  // Contoh:
  Future<List<Map<String, dynamic>>> fetchNavigationData() async {
    // TODO: Implement service logic
    await Future.delayed(const Duration(seconds: 1));
    return [
      {"id": 1, "name": "Navigation One"},
      {"id": 2, "name": "Navigation Two"},
    ];
  }
}
