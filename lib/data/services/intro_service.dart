class IntroService {
  // Misal: method untuk fetch data dari API atau database
  // Contoh:
  Future<List<Map<String, dynamic>>> fetchIntroData() async {
    // TODO: Implement service logic
    await Future.delayed(const Duration(seconds: 1));
    return [
      {"id": 1, "name": "Intro One"},
      {"id": 2, "name": "Intro Two"},
    ];
  }
}
