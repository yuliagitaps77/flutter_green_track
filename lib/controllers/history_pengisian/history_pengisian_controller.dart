import 'package:get/get.dart';

class BibitModel {
  final String id;
  final String nama;
  final String varietas;
  final String usia;
  final String fungsi;
  final String deskripsi;

  BibitModel({
    required this.id,
    required this.nama,
    required this.varietas,
    required this.usia,
    required this.fungsi,
    required this.deskripsi,
  });
}

class HistoryPengisianController extends GetxController {
  final RxList<BibitModel> _hariIniList = <BibitModel>[].obs;
  final RxList<BibitModel> _kemarinList = <BibitModel>[].obs;

  List<BibitModel> get hariIniList => _hariIniList;
  List<BibitModel> get kemarinList => _kemarinList;

  @override
  void onInit() {
    super.onInit();
    _fetchHariIniData();
    _fetchKemarinData();
  }

  // Simulasi pengambilan data untuk hari ini
  void _fetchHariIniData() {
    // Contoh data (dalam implementasi nyata, data akan diambil dari API atau database)
    _hariIniList.value = [
      BibitModel(
          id: '1',
          nama: 'Pohon Mangga',
          varietas: 'Mangga Harum Manis',
          usia: '3 bulan',
          fungsi: 'Tanaman buah, penaung, peneduh',
          deskripsi:
              'Pohon mangga merupakan tanaman buah yang memiliki banyak manfaat. Selain menghasilkan buah yang manis, pohon mangga juga berfungsi sebagai peneduh dan dapat menyerap polusi udara.'),
      BibitModel(
          id: '2',
          nama: 'Pohon Jati',
          varietas: 'Jati Emas',
          usia: '6 bulan',
          fungsi: 'Tanaman kayu, pencegah erosi',
          deskripsi:
              'Pohon jati merupakan tanaman kayu berkualitas tinggi. Akarnya yang kuat dapat mencegah erosi tanah dan kayunya memiliki nilai ekonomi yang tinggi.'),
      BibitModel(
          id: '3',
          nama: 'Pohon Ketapang',
          varietas: 'Ketapang Kencana',
          usia: '2 bulan',
          fungsi: 'Tanaman peneduh, estetika',
          deskripsi:
              'Pohon ketapang memiliki bentuk yang indah dan rindang, sehingga sering digunakan sebagai tanaman hias dan peneduh di taman kota atau jalanan.'),
    ];
  }

  // Simulasi pengambilan data untuk kemarin
  void _fetchKemarinData() {
    // Contoh data (dalam implementasi nyata, data akan diambil dari API atau database)
    _kemarinList.value = [
      BibitModel(
          id: '4',
          nama: 'Pohon Mahoni',
          varietas: 'Mahoni Daun Lebar',
          usia: '4 bulan',
          fungsi: 'Tanaman kayu, penyerap polusi',
          deskripsi:
              'Pohon mahoni memiliki kemampuan menyerap polusi udara dengan baik. Kayunya juga bernilai ekonomi tinggi dan sering digunakan untuk furnitur.'),
      BibitModel(
          id: '5',
          nama: 'Pohon Trembesi',
          varietas: 'Trembesi Raksasa',
          usia: '8 bulan',
          fungsi: 'Penyerap karbon, peneduh',
          deskripsi:
              'Pohon trembesi mampu menyerap karbon dioksida dalam jumlah besar, sehingga sering disebut sebagai pohon paru-paru kota. Bentuknya yang rindang juga menjadikannya tanaman peneduh yang baik.'),
    ];
  }

  // Method untuk menambah bibit baru (bisa ditambahkan sesuai kebutuhan)
  void addBibit(BibitModel bibit, bool isToday) {
    if (isToday) {
      _hariIniList.add(bibit);
    } else {
      _kemarinList.add(bibit);
    }
  }

  // Method untuk menghapus bibit (bisa ditambahkan sesuai kebutuhan)
  void removeBibit(String id, bool isToday) {
    if (isToday) {
      _hariIniList.removeWhere((bibit) => bibit.id == id);
    } else {
      _kemarinList.removeWhere((bibit) => bibit.id == id);
    }
  }
}
