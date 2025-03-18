import '../models/intro_model.dart';
import '../services/intro_service.dart';

class IntroRepository {
  final IntroService service = IntroService();

  Future<List<IntroModel>> getAllIntro() async {
    final data = await service.fetchIntroData();
    return data.map((json) => IntroModel.fromJson(json)).toList();
  }
}
