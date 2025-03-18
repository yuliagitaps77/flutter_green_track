class AuthenticationService {
  // Misal: method untuk fetch data dari API atau database
  // Contoh:
  Future<List<Map<String, dynamic>>> fetchAuthenticationData() async {
    // TODO: Implement service logic
    await Future.delayed(const Duration(seconds: 1));
    return [
      {"id": 1, "name": "Authentication One"},
      {"id": 2, "name": "Authentication Two"},
    ];
  }
}
