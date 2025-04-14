class BibitModel {
  final String id;
  final String jenisBibit;
  final String umur;
  final double tinggi;
  final String kondisi;
  final String tanggalTanam;
  final String lokasi;
  final bool siapTanam;
  final bool butuhPerhatian;

  BibitModel({
    required this.id,
    required this.jenisBibit,
    required this.umur,
    required this.tinggi,
    required this.kondisi,
    required this.tanggalTanam,
    required this.lokasi,
    this.siapTanam = false,
    this.butuhPerhatian = false,
  });
}
