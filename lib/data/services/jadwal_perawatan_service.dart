class JadwalPerawatanService {
  // Misal: method untuk fetch data dari API atau database
  // Contoh:
  Future<List<Map<String, dynamic>>> fetchJadwalPerawatanData() async {
    // TODO: Implement service logic
    await Future.delayed(const Duration(seconds: 1));
    return [
      {"id": 1, "name": "JadwalPerawatan One"},
      {"id": 2, "name": "JadwalPerawatan Two"},
    ];
  }
}
