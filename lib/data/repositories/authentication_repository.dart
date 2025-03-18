import '../models/authentication_model.dart';
import '../services/authentication_service.dart';

class AuthenticationRepository {
  final AuthenticationService service = AuthenticationService();

  Future<List<AuthenticationModel>> getAllAuthentication() async {
    final data = await service.fetchAuthenticationData();
    return data.map((json) => AuthenticationModel.fromJson(json)).toList();
  }
}
