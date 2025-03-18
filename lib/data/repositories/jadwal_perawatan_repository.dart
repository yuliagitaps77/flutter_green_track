import '../models/jadwal_perawatan_model.dart';
import '../services/jadwal_perawatan_service.dart';

class JadwalPerawatanRepository {
  final JadwalPerawatanService service = JadwalPerawatanService();

  Future<List<JadwalPerawatanModel>> getAllJadwalPerawatan() async {
    final data = await service.fetchJadwalPerawatanData();
    return data.map((json) => JadwalPerawatanModel.fromJson(json)).toList();
  }
}
