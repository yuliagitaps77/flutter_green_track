import '../models/navigation_model.dart';
import '../services/navigation_service.dart';

class NavigationRepository {
  final NavigationService service = NavigationService();

  Future<List<NavigationModel>> getAllNavigation() async {
    final data = await service.fetchNavigationData();
    return data.map((json) => NavigationModel.fromJson(json)).toList();
  }
}
