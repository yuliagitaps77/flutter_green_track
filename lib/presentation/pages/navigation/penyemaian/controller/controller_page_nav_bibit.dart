import 'package:flutter/material.dart';
import 'package:flutter_green_track/presentation/pages/navigation/penyemaian/model/model_bibit.dart';
import 'package:get/get.dart';

class BibitController extends GetxController {
  // Data
  final RxList<Bibit> _bibitList = <Bibit>[].obs;
  final RxList<Bibit> _filteredBibitList = <Bibit>[].obs;
  final RxString _selectedCategory = 'Semua'.obs;
  final RxString _searchQuery = ''.obs;

  // Getters
  List<Bibit> get bibitList => _bibitList;
  List<Bibit> get filteredBibitList => _filteredBibitList;
  String get selectedCategory => _selectedCategory.value;
  String get searchQuery => _searchQuery.value;

  @override
  void onInit() {
    super.onInit();
    // Initialize with dummy data
    _bibitList.addAll(_getDummyBibitData());
    // Initial filter to show all items
    _filteredBibitList.assignAll(_bibitList);
  }

  // Filter by search query
  void filterBibit(String query) {
    _searchQuery.value = query;
    _applyFilters();
  }

  // Filter by category
  void filterByCategory(String category) {
    _selectedCategory.value = category;
    _applyFilters();
  }

  // Apply both filters
  void _applyFilters() {
    if (_selectedCategory.value == 'Semua' && _searchQuery.value.isEmpty) {
      _filteredBibitList.assignAll(_bibitList);
    } else {
      _filteredBibitList.assignAll(_bibitList.where((bibit) {
        bool matchesCategory = _selectedCategory.value == 'Semua' ||
            bibit.kategori == _selectedCategory.value;
        bool matchesSearch = _searchQuery.value.isEmpty ||
            bibit.nama.toLowerCase().contains(_searchQuery.value.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList());
    }
  }

  // Method untuk menambah bibit baru
  void tambahBibit(Bibit bibit) {
    _bibitList.add(bibit);
    _applyFilters();
  }

  // Method untuk menghapus bibit
  void hapusBibit(String id) {
    _bibitList.removeWhere((bibit) => bibit.id == id);
    _applyFilters();
  }

  // Method untuk mengubah bibit
  void updateBibit(Bibit updatedBibit) {
    final index = _bibitList.indexWhere((bibit) => bibit.id == updatedBibit.id);
    if (index != -1) {
      _bibitList[index] = updatedBibit;
      _applyFilters();
    }
  }

  // Method untuk menyimpan ke penyimpanan lokal
  Future<void> saveBibitToStorage() async {
    // Implementasi penyimpanan ke SharedPreferences atau Hive
    // Contoh implementasi:
    // final prefs = await SharedPreferences.getInstance();
    // final bibitListJson = _bibitList.map((bibit) => bibit.toJson()).toList();
    // await prefs.setString('bibit_list', jsonEncode(bibitListJson));
  }

  // Method untuk memuat dari penyimpanan lokal
  Future<void> loadBibitFromStorage() async {
    // Implementasi loading dari SharedPreferences atau Hive
    // Contoh implementasi:
    // final prefs = await SharedPreferences.getInstance();
    // final bibitListString = prefs.getString('bibit_list');
    // if (bibitListString != null) {
    //   final bibitListJson = jsonDecode(bibitListString) as List;
    //   _bibitList.assignAll(bibitListJson.map((json) => Bibit.fromJson(json)).toList());
    //   _applyFilters();
    // }
  }

  // Method untuk mendapatkan bibit berdasarkan id
  Bibit? getBibitById(String id) {
    try {
      return _bibitList.firstWhere((bibit) => bibit.id == id);
    } catch (e) {
      return null;
    }
  }

  // Method untuk mendapatkan bibit berdasarkan kategori
  List<Bibit> getBibitByCategory(String category) {
    return _bibitList.where((bibit) => bibit.kategori == category).toList();
  }

  // Method untuk mengurutkan bibit
  void sortBibit({required String by, bool ascending = true}) {
    switch (by) {
      case 'nama':
        _bibitList.sort((a, b) =>
            ascending ? a.nama.compareTo(b.nama) : b.nama.compareTo(a.nama));
        break;
      case 'kategori':
        _bibitList.sort((a, b) => ascending
            ? a.kategori.compareTo(b.kategori)
            : b.kategori.compareTo(a.kategori));
        break;
      case 'masaPanen':
        _bibitList.sort((a, b) => ascending
            ? a.masaPanen.compareTo(b.masaPanen)
            : b.masaPanen.compareTo(a.masaPanen));
        break;
      default:
        _bibitList.sort((a, b) =>
            ascending ? a.nama.compareTo(b.nama) : b.nama.compareTo(a.nama));
    }
    _applyFilters();
  }

  // Dummy data generator
  List<Bibit> _getDummyBibitData() {
    return [
      Bibit(
        id: '1',
        nama: 'Tomat Cherry',
        kategori: 'Sayuran',
        icon: Icons.eco,
        kebutuhanAir: 'Sedang',
        kebutuhanSinar: 'Tinggi',
        suhuIdeal: '22-28',
        masaPanen: 70,
        deskripsi:
            'Tomat cherry adalah jenis tomat berukuran kecil yang memiliki rasa manis dan segar. Sangat cocok untuk dijadikan salad atau garnish dalam masakan.',
        langkahPenanaman: [
          'Siapkan media tanam dengan campuran tanah dan kompos.',
          'Tanam benih tomat dengan kedalaman 1-2 cm.',
          'Siram secara teratur, jaga kelembaban tanah.',
          'Berikan pupuk setiap 2 minggu sekali.',
          'Pasang ajir untuk menopang tanaman saat mulai berbuah.'
        ],
        manfaat: [
          'Kaya akan vitamin C dan antioksidan',
          'Membantu menjaga kesehatan jantung',
          'Baik untuk kesehatan kulit',
          'Mendukung kesehatan pencernaan'
        ],
      ),
      Bibit(
        id: '2',
        nama: 'Cabai Rawit',
        kategori: 'Sayuran',
        icon: Icons.local_fire_department,
        kebutuhanAir: 'Sedang',
        kebutuhanSinar: 'Tinggi',
        suhuIdeal: '24-32',
        masaPanen: 90,
        deskripsi:
            'Cabai rawit adalah varietas cabai yang kecil namun sangat pedas. Tanaman ini relatif mudah dibudidayakan dan dapat tumbuh di berbagai jenis tanah.',
        langkahPenanaman: [
          'Rendam benih cabai dalam air hangat selama 6 jam.',
          'Semai benih pada media tanam yang gembur.',
          'Pindahkan bibit ke pot atau lahan setelah memiliki 4 daun.',
          'Siram secara teratur, hindari tergenang air.',
          'Berikan pupuk saat tanaman berusia 1 bulan.'
        ],
        manfaat: [
          'Mengandung capsaicin yang bersifat antiinflamasi',
          'Membantu meningkatkan metabolisme tubuh',
          'Kaya akan vitamin C dan A',
          'Memiliki sifat antibakteri'
        ],
      ),
      Bibit(
        id: '3',
        nama: 'Selada Keriting',
        kategori: 'Sayuran',
        icon: Icons.spa,
        kebutuhanAir: 'Tinggi',
        kebutuhanSinar: 'Sedang',
        suhuIdeal: '15-22',
        masaPanen: 45,
        deskripsi:
            'Selada keriting adalah jenis selada dengan daun bergelombang. Memiliki tekstur renyah dan rasa yang segar, sangat cocok untuk salad dan hiasan hidangan.',
        langkahPenanaman: [
          'Taburkan benih di permukaan media tanam.',
          'Tutup tipis dengan tanah atau kompos halus.',
          'Jaga kelembaban tanah dengan penyiraman rutin.',
          'Hindari terkena sinar matahari langsung terlalu lama.',
          'Panen sebelum tanaman berbunga untuk rasa terbaik.'
        ],
        manfaat: [
          'Sumber serat yang baik untuk pencernaan',
          'Rendah kalori, cocok untuk diet',
          'Mengandung vitamin K untuk kesehatan tulang',
          'Kaya akan folat dan antioksidan'
        ],
      ),
      Bibit(
        id: '4',
        nama: 'Stroberi',
        kategori: 'Buah',
        icon: Icons.bubble_chart,
        kebutuhanAir: 'Sedang',
        kebutuhanSinar: 'Sedang',
        suhuIdeal: '20-26',
        masaPanen: 120,
        deskripsi:
            'Stroberi adalah buah berwarna merah dengan rasa manis dan sedikit asam. Tanaman ini dapat tumbuh dengan baik di pot atau kebun rumah.',
        langkahPenanaman: [
          'Pilih bibit stroberi yang sehat.',
          'Tanam dalam pot dengan kedalaman 10-15 cm.',
          'Pastikan drainase pot baik untuk mencegah genangan air.',
          'Berikan sinar matahari pagi selama 6-8 jam per hari.',
          'Siram secara teratur, jangan sampai terlalu kering atau basah.'
        ],
        manfaat: [
          'Kaya akan vitamin C dan antioksidan',
          'Membantu menurunkan kadar kolesterol',
          'Baik untuk kesehatan jantung',
          'Membantu mencerahkan kulit'
        ],
      ),
      Bibit(
        id: '5',
        nama: 'Rosemary',
        kategori: 'Rempah',
        icon: Icons.grass,
        kebutuhanAir: 'Rendah',
        kebutuhanSinar: 'Tinggi',
        suhuIdeal: '18-24',
        masaPanen: 90,
        deskripsi:
            'Rosemary adalah tanaman herba aromatik dengan daun berbentuk jarum. Sering digunakan sebagai bumbu masakan dan memiliki aroma yang khas.',
        langkahPenanaman: [
          'Stek batang rosemary dengan panjang 10-15 cm.',
          'Tanam dalam pot dengan media tanam yang kering.',
          'Taruh di tempat yang terkena sinar matahari langsung.',
          'Siram ketika tanah mulai kering, hindari terlalu basah.',
          'Pangkas secara teratur untuk mendorong pertumbuhan baru.'
        ],
        manfaat: [
          'Mengandung antioksidan dan senyawa anti-inflamasi',
          'Membantu meningkatkan konsentrasi dan memori',
          'Memiliki sifat antibakteri dan antijamur',
          'Dapat membantu mengurangi stres'
        ],
      ),
      Bibit(
        id: '6',
        nama: 'Lavender',
        kategori: 'Tanaman Hias',
        icon: Icons.filter_vintage,
        kebutuhanAir: 'Rendah',
        kebutuhanSinar: 'Tinggi',
        suhuIdeal: '18-24',
        masaPanen: 180,
        deskripsi:
            'Lavender adalah tanaman berbunga dengan aroma yang menenangkan. Selain sebagai tanaman hias, bunganya juga bisa dimanfaatkan untuk aromaterapi dan bahan kosmetik.',
        langkahPenanaman: [
          'Siapkan media tanam dengan campuran tanah dan pasir.',
          'Tanam bibit lavender dengan jarak 30-40 cm antar tanaman.',
          'Tempatkan di area yang terkena sinar matahari penuh.',
          'Siram secukupnya, lavender lebih suka kondisi kering.',
          'Pangkas bunga yang sudah layu untuk mendorong pertumbuhan baru.'
        ],
        manfaat: [
          'Membantu meredakan stres dan kecemasan',
          'Meningkatkan kualitas tidur',
          'Mengusir nyamuk dan serangga',
          'Memiliki khasiat antiseptik'
        ],
      ),
      Bibit(
        id: '7',
        nama: 'Lidah Buaya',
        kategori: 'Tanaman Hias',
        icon: Icons.healing,
        kebutuhanAir: 'Rendah',
        kebutuhanSinar: 'Sedang',
        suhuIdeal: '20-30',
        masaPanen: 120,
        deskripsi:
            'Lidah buaya atau aloe vera adalah tanaman sukulen dengan daun tebal berisi gel. Selain sebagai tanaman hias, juga banyak digunakan untuk perawatan kulit dan kesehatan.',
        langkahPenanaman: [
          'Gunakan media tanam berpasir dengan drainase baik.',
          'Tanam bibit dengan kedalaman sekitar 5-7 cm.',
          'Tempatkan di area dengan sinar matahari tidak langsung.',
          'Siram hanya ketika tanah benar-benar kering.',
          'Hindari penyiraman berlebih karena dapat menyebabkan pembusukan akar.'
        ],
        manfaat: [
          'Menenangkan dan melembabkan kulit',
          'Membantu mempercepat penyembuhan luka',
          'Memiliki sifat anti-inflamasi',
          'Dapat membantu melancarkan pencernaan'
        ],
      ),
      Bibit(
        id: '8',
        nama: 'Jahe',
        kategori: 'Rempah',
        icon: Icons.set_meal,
        kebutuhanAir: 'Sedang',
        kebutuhanSinar: 'Sedang',
        suhuIdeal: '22-30',
        masaPanen: 240,
        deskripsi:
            'Jahe adalah tanaman rimpang yang dikenal dengan rasa pedas dan hangatnya. Banyak digunakan sebagai bumbu masakan, minuman, dan bahan obat tradisional.',
        langkahPenanaman: [
          'Pilih rimpang jahe yang segar dengan tunas.',
          'Potong rimpang menjadi beberapa bagian dengan minimal satu tunas.',
          'Tanam dengan kedalaman 5-7 cm, tunas menghadap ke atas.',
          'Siram secara teratur untuk menjaga kelembaban tanah.',
          'Berikan pupuk organik setiap 4-6 minggu sekali.'
        ],
        manfaat: [
          'Membantu mengatasi mual dan gangguan pencernaan',
          'Memiliki sifat anti-inflamasi dan antioksidan',
          'Membantu meningkatkan sistem kekebalan tubuh',
          'Dapat membantu meredakan sakit kepala dan nyeri otot'
        ],
      ),
      Bibit(
        id: '9',
        nama: 'Bayam',
        kategori: 'Sayuran',
        icon: Icons.eco_outlined,
        kebutuhanAir: 'Sedang',
        kebutuhanSinar: 'Sedang',
        suhuIdeal: '18-24',
        masaPanen: 30,
        deskripsi:
            'Bayam adalah sayuran berdaun hijau yang kaya nutrisi dan mudah dibudidayakan. Cocok untuk pemula karena pertumbuhannya yang cepat dan perawatan yang sederhana.',
        langkahPenanaman: [
          'Taburkan benih di tanah yang sudah digemburkan.',
          'Tutup tipis dengan tanah, jarak antar benih sekitar 5 cm.',
          'Siram secara teratur setiap pagi dan sore.',
          'Berikan pupuk organik setelah tanaman berusia 1 minggu.',
          'Panen dengan mencabut seluruh tanaman atau memetik daun-daun luar.'
        ],
        manfaat: [
          'Kaya akan zat besi dan kalsium',
          'Mengandung vitamin A, C, dan K dalam jumlah tinggi',
          'Membantu menjaga kesehatan mata',
          'Mendukung fungsi pencernaan yang sehat'
        ],
      ),
      Bibit(
        id: '10',
        nama: 'Pepaya',
        kategori: 'Buah',
        icon: Icons.spa_outlined,
        kebutuhanAir: 'Sedang',
        kebutuhanSinar: 'Tinggi',
        suhuIdeal: '25-30',
        masaPanen: 300,
        deskripsi:
            'Pepaya adalah tanaman buah tropis yang cepat berbuah dan memiliki banyak manfaat kesehatan. Buahnya manis dan memiliki daging berwarna oranye kaya nutrisi.',
        langkahPenanaman: [
          'Ambil biji dari buah pepaya matang dan keringkan selama 2 hari.',
          'Tanam biji dengan kedalaman 1-2 cm di tanah yang gembur.',
          'Siram secara teratur, jaga kelembaban tanah.',
          'Tempatkan di area yang terkena sinar matahari penuh.',
          'Berikan pupuk organik setiap 2 bulan sekali.'
        ],
        manfaat: [
          'Mengandung enzim papain yang membantu pencernaan',
          'Kaya akan antioksidan dan vitamin C',
          'Membantu menjaga kesehatan kulit',
          'Mendukung sistem kekebalan tubuh'
        ],
      ),
    ];
  }
}
