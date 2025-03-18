import '../models/dashboard_tpk_model.dart';
import '../services/dashboard_tpk_service.dart';

class DashboardTpkRepository {
  final DashboardTpkService service = DashboardTpkService();

  Future<List<DashboardTpkModel>> getAllDashboardTpk() async {
    final data = await service.fetchDashboardTpkData();
    return data.map((json) => DashboardTpkModel.fromJson(json)).toList();
  }
}
