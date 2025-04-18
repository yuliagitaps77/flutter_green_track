// File: admin/admin_account_creator_screen.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAccountCreatorScreen extends StatefulWidget {
  @override
  _AdminAccountCreatorScreenState createState() =>
      _AdminAccountCreatorScreenState();
}

class _AdminAccountCreatorScreenState extends State<AdminAccountCreatorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Selected role
  String _selectedRole = 'admin_penyemaian';

  // Loading state
  bool _isLoading = false;

  // Firebase instances
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // List of accounts (for displaying in the list)
  List<Map<String, dynamic>> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

// Create new account
  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final role = _selectedRole;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user in Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user data to Firestore
      await _firestore.collection('akun').doc(userCredential.user!.uid).set({
        'email': email,
        'nama_lengkap': name,
        'role': [role],
        'last_login': null,
        'kode_otp': '',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'dashboard': role == 'admin_penyemaian'
            ? {
                'total_bibit': 0,
                'bibit_siap_tanam': 0,
                'butuh_perhatian': 0,
                'total_bibit_dipindai': 0,
                'last_updated': FieldValue.serverTimestamp()
              }
            : {
                'total_kayu': 0,
                'total_kayu_dipindai': 0,
                'total_batch': 0,
                'last_updated': FieldValue.serverTimestamp()
              }
      });

      // Buat data dummy untuk akun baru berdasarkan role
      if (role == 'admin_penyemaian') {
        await _generateSimpleBibitData(userCredential.user!.uid, 20);
      } else if (role == 'admin_tpk') {
        await _generateSimpleKayuData(userCredential.user!.uid, 20);
      }

      // Clear form
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();

      // Refresh account list
      await _loadAccounts();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Akun berhasil dibuat dengan data awal'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Terjadi kesalahan saat membuat akun';

      if (e.code == 'weak-password') {
        errorMessage = 'Password terlalu lemah';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email sudah digunakan';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print('Error creating account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Generate dummy accounts
  Future<void> _generateDummyAccounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<Map<String, dynamic>> dummyUsers = [
        {
          'email': 'penyemaian1@example.com',
          'password': 'Password123',
          'nama_lengkap': 'Admin Penyemaian 1',
          'role': ['admin_penyemaian'],
        },
        {
          'email': 'penyemaian2@example.com',
          'password': 'Password123',
          'nama_lengkap': 'Admin Penyemaian 2',
          'role': ['admin_penyemaian'],
        },
        {
          'email': 'tpk1@example.com',
          'password': 'Password123',
          'nama_lengkap': 'Admin TPK 1',
          'role': ['admin_tpk'],
        },
        {
          'email': 'tpk2@example.com',
          'password': 'Password123',
          'nama_lengkap': 'Admin TPK 2',
          'role': ['admin_tpk'],
        },
      ];

      for (final user in dummyUsers) {
        try {
          // Check if email already exists
          final QuerySnapshot existingUser = await _firestore
              .collection('akun')
              .where('email', isEqualTo: user['email'])
              .limit(1)
              .get();

          if (existingUser.docs.isNotEmpty) {
            print('User ${user['email']} already exists, skipping...');
            continue;
          }

          // Create user in Firebase Auth
          UserCredential userCredential =
              await _auth.createUserWithEmailAndPassword(
            email: user['email'] as String,
            password: user['password'] as String,
          );

          // Add user data to Firestore
          await _firestore
              .collection('akun')
              .doc(userCredential.user!.uid)
              .set({
            'email': user['email'],
            'nama_lengkap': user['nama_lengkap'],
            'role': user['role'],
            'last_login': null,
            'kode_otp': '',
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });

          // Setup initial dashboard data
          if ((user['role'] as List<dynamic>).contains('admin_penyemaian')) {
            await _firestore
                .collection('dashboard_informasi_admin_penyemaian')
                .doc(userCredential.user!.uid)
                .set({
              'total_bibit': 1245,
              'bibit_siap_tanam': 482,
              'butuh_perhatian': 23,
              'total_bibit_dipindai': 87,
              'previous_total_bibit': 1083,
              'created_at': FieldValue.serverTimestamp(),
              'updated_at': FieldValue.serverTimestamp(),
            });
          } else if ((user['role'] as List<dynamic>).contains('admin_tpk')) {
            await _firestore
                .collection('dashboard_informasi_admin_tpk')
                .doc(userCredential.user!.uid)
                .set({
              'total_kayu': 782,
              'total_kayu_dipindai': 326,
              'total_batch': 15,
              'created_at': FieldValue.serverTimestamp(),
              'updated_at': FieldValue.serverTimestamp(),
            });
          }

          // Create dummy activities
          final List<Map<String, dynamic>> activities = [
            {
              'nama_aktivitas': 'Scan Barcode Bibit Mahoni',
              'tanggal_waktu': Timestamp.now(),
              'created_at': FieldValue.serverTimestamp(),
              'updated_at': FieldValue.serverTimestamp(),
            },
            {
              'nama_aktivitas': 'Pembaruan Data Bibit Jati',
              'tanggal_waktu': Timestamp.fromDate(
                DateTime.now().subtract(Duration(hours: 2)),
              ),
              'created_at': FieldValue.serverTimestamp(),
              'updated_at': FieldValue.serverTimestamp(),
            },
            {
              'nama_aktivitas': 'Pencetakan 25 Barcode',
              'tanggal_waktu': Timestamp.fromDate(
                DateTime.now().subtract(Duration(days: 1, hours: 8)),
              ),
              'created_at': FieldValue.serverTimestamp(),
              'updated_at': FieldValue.serverTimestamp(),
            },
            {
              'nama_aktivitas': 'Pendaftaran 30 Bibit Baru',
              'tanggal_waktu': Timestamp.fromDate(
                DateTime.now().subtract(Duration(days: 1, hours: 10)),
              ),
              'created_at': FieldValue.serverTimestamp(),
              'updated_at': FieldValue.serverTimestamp(),
            },
          ];

          for (final activity in activities) {
            await _firestore.collection('aktivitas').add({
              ...activity,
              'id_user': userCredential.user!.uid,
            });
          }
        } catch (e) {
          print('Error creating dummy user ${user['email']}: $e');
        }
      }

      // Refresh account list
      await _loadAccounts();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Akun dummy berhasil dibuat'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error generating dummy accounts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateSimpleDummyAccounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Daftar akun dummy sederhana
      final List<Map<String, dynamic>> dummyUsers = [
        {
          'email': 'superadmin@example.com',
          'password': 'Admin123',
          'nama_lengkap': 'Super Admin',
          'role': ['admin_penyemaian', 'admin_tpk'],
        },
        {
          'email': 'penyemaian@example.com',
          'password': 'Admin123',
          'nama_lengkap': 'Admin Penyemaian',
          'role': ['admin_penyemaian'],
        },
        {
          'email': 'tpk@example.com',
          'password': 'Admin123',
          'nama_lengkap': 'Admin TPK',
          'role': ['admin_tpk'],
        },
      ];

      for (final user in dummyUsers) {
        try {
          // Buat akun di Firebase Auth
          UserCredential userCredential =
              await _auth.createUserWithEmailAndPassword(
            email: user['email'] as String,
            password: user['password'] as String,
          );

          // Tambahkan data ke Firestore
          await _firestore
              .collection('akun')
              .doc(userCredential.user!.uid)
              .set({
            'email': user['email'],
            'nama_lengkap': user['nama_lengkap'],
            'role': user['role'],
            'last_login': null,
            'kode_otp': '',
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });

          // Buat data dashboard sederhana
          if ((user['role'] as List<dynamic>).contains('admin_penyemaian')) {
            await _generateSimpleBibitData(userCredential.user!.uid, 50);
          }

          if ((user['role'] as List<dynamic>).contains('admin_tpk')) {
            await _generateSimpleKayuData(userCredential.user!.uid, 50);
          }

          print('Berhasil membuat akun: ${user['email']}');
        } catch (e) {
          print('Error membuat akun ${user['email']}: $e');
          // Lanjutkan ke akun berikutnya jika terjadi error
        }
      }

      // Refresh daftar akun setelah selesai
      await _loadAccounts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Akun dummy berhasil dibuat'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error generating simple dummy accounts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk membuat data bibit sederhana
// Fungsi untuk membuat data bibit sederhana dengan jadwal perawatan
  Future<void> _generateSimpleBibitData(String userId, int count) async {
    final jenisBibit = ['Mahoni', 'Jati', 'Sengon', 'Meranti', 'Eboni'];
    final varietas = ['Lokal', 'Unggul', 'Hybrid'];
    final kondisi = ['Baik', 'Butuh Perawatan', 'Siap Tanam'];
    final Random random = Random();

    // Jenis perawatan untuk jadwal
    final List<String> jenisPerawatan = [
      'Penyiraman',
      'Pemupukan',
      'Pengendalian Hama',
      'Pemindahan Pot',
      'Pemangkasan'
    ];

    // Untuk menghitung statistik
    int totalBibit = 0;
    int bibitSiapTanam = 0;
    int butuhPerhatian = 0;
    int totalBibitDipindai = 0;

    // Buat data bibit sederhana
    for (int i = 0; i < count; i++) {
      final String namaBibit = jenisBibit[random.nextInt(jenisBibit.length)];
      final String varietasBibit = varietas[random.nextInt(varietas.length)];
      final String kondisiBibit = kondisi[random.nextInt(kondisi.length)];
      final int usia = 1 + random.nextInt(24); // 1-24 bulan
      final double tinggi = 10 + random.nextDouble() * 90; // 10-100 cm

      final bibitRef = _firestore.collection('bibit').doc();

      await bibitRef.set({
        'id_user': userId,
        'nama_bibit': namaBibit,
        'varietas': varietasBibit,
        'usia': usia,
        'tinggi': tinggi,
        'jenis_bibit': 'Pohon',
        'kondisi': kondisiBibit,
        'status_hama': 'Tidak Ada',
        'media_tanam': 'Tanah',
        'nutrisi': 'NPK',
        'asal_bibit': 'Lokal',
        'produktivitas': random.nextDouble() * 5,
        'catatan': 'Bibit $namaBibit varietas $varietasBibit',
        'created_at': FieldValue.serverTimestamp(),
        'tanggal_pembibitan': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: random.nextInt(365)))),
        'gambar_image': [
          'https://via.placeholder.com/150?text=Bibit+$namaBibit',
        ],
        'barcode':
            'BT${DateTime.now().millisecondsSinceEpoch}${random.nextInt(1000)}',
        'url_bibit': 'https://yourapp.com/bibit/${bibitRef.id}',
        'lokasi_tanam': {
          'lat': -6.2 + random.nextDouble(),
          'lng': 106.8 + random.nextDouble(),
          'alamat': 'Lokasi Tanam Sample',
        },
        'updated_at': FieldValue.serverTimestamp()
      });

      // Buat jadwal perawatan untuk bibit ini (1-3 jadwal)
      final int jadwalCount = 1 + random.nextInt(3);
      for (int j = 0; j < jadwalCount; j++) {
        // Pilih jenis perawatan secara acak
        final String jenis =
            jenisPerawatan[random.nextInt(jenisPerawatan.length)];

        // Jadwal untuk 1-30 hari ke depan
        final DateTime jadwalDate =
            DateTime.now().add(Duration(days: 1 + random.nextInt(30)));

        // Buat dokumen jadwal perawatan
        await bibitRef.collection('jadwal_perawatan').add({
          'id_user': userId,
          'jadwal': Timestamp.fromDate(jadwalDate),
          'jenis_perawatan': jenis,
          'judul_perawatan': 'Jadwal $jenis $namaBibit',
          'deskripsi':
              'Lakukan $jenis pada bibit $namaBibit varietas $varietasBibit sesuai dengan prosedur standar.',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp()
        });
      }

      // Update statistik
      totalBibit++;
      if (kondisiBibit == 'Siap Tanam') bibitSiapTanam++;
      if (kondisiBibit == 'Butuh Perawatan') butuhPerhatian++;

      // Buat riwayat pindai untuk 30% bibit
      if (random.nextDouble() < 0.3) {
        await bibitRef.collection('pengisian_history').add({
          'id_user': userId,
          'tanggal': Timestamp.fromDate(
              DateTime.now().subtract(Duration(days: random.nextInt(30)))),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp()
        });

        totalBibitDipindai++;
      }
    }

    // Update statistik di akun pengguna
    await _firestore
        .collection('dashboard_informasi_admin_penyemaian')
        .doc(userId)
        .set({
      'total_bibit': totalBibit,
      'bibit_siap_tanam': bibitSiapTanam,
      'butuh_perhatian': butuhPerhatian,
      'total_bibit_dipindai': totalBibitDipindai,
      'previous_total_bibit': totalBibit > 10 ? totalBibit - 10 : 0,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp()
    });
  }

  // Fungsi untuk membuat data kayu sederhana
  Future<void> _generateSimpleKayuData(String userId, int count) async {
    final jenisKayu = ['Mahoni', 'Jati', 'Sengon', 'Meranti', 'Sonokeling'];
    final varietas = ['Lokal', 'Unggul', 'Premium'];
    final batchPanen = ['BATCH-2025-01', 'BATCH-2025-02', 'BATCH-2025-03'];
    final Random random = Random();

    // Untuk menghitung statistik
    int totalKayu = 0;
    int totalKayuDipindai = 0;
    Set<String> uniqueBatches = {};

    // Buat data kayu sederhana
    for (int i = 0; i < count; i++) {
      final String namaKayu = jenisKayu[random.nextInt(jenisKayu.length)];
      final String varietasKayu = varietas[random.nextInt(varietas.length)];
      final String batch = batchPanen[random.nextInt(batchPanen.length)];
      uniqueBatches.add(batch);

      final int usia = 24 + random.nextInt(120); // 2-12 tahun (dalam bulan)
      final double tinggi = 200 + random.nextDouble() * 800; // 2-10 meter

      final kayuRef = _firestore.collection('kayu').doc();

      await kayuRef.set({
        'id_user': userId,
        'nama_kayu': namaKayu,
        'varietas': varietasKayu,
        'usia': usia,
        'tinggi': tinggi,
        'jenis_kayu': 'Hardwood',
        'catatan': 'Kayu $namaKayu batch $batch',
        'created_at': FieldValue.serverTimestamp(),
        'tanggal_lahir_pohon': Timestamp.fromDate(DateTime.now()
            .subtract(Duration(days: 365 * (2 + random.nextInt(8))))),
        'gambar_image': [
          'https://via.placeholder.com/150?text=Kayu+$namaKayu',
        ],
        'barcode':
            'KY${DateTime.now().millisecondsSinceEpoch}${random.nextInt(1000)}',
        'url_bibit': 'https://yourapp.com/kayu/${kayuRef.id}',
        'lokasi_tanam': 'Area Tanam Sample',
        'batch_panen': batch,
        'updated_at': FieldValue.serverTimestamp()
      });

      // Update statistik
      totalKayu++;

      // Buat riwayat scan untuk 40% kayu
      if (random.nextDouble() < 0.4) {
        await kayuRef.collection('riwayat_scan').add({
          'id_user': userId,
          'tanggal': Timestamp.fromDate(
              DateTime.now().subtract(Duration(days: random.nextInt(60)))),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp()
        });

        totalKayuDipindai++;
      }
    }

    // Update statistik di akun pengguna
    await _firestore.collection('akun').doc(userId).update({
      'dashboard': {
        'total_kayu': totalKayu,
        'total_kayu_dipindai': totalKayuDipindai,
        'total_batch': uniqueBatches.length,
        'last_updated': FieldValue.serverTimestamp()
      }
    });
  }

  // Fungsi perbaikan untuk _loadAccounts - tanpa orderBy yang bermasalah
  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Query tanpa orderBy
      final QuerySnapshot snapshot = await _firestore.collection('akun').get();

      setState(() {
        _accounts = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'nama_lengkap': data['nama_lengkap'] ?? 'Tidak ada nama',
            'email': data['email'] ?? 'Tidak ada email',
            'role': (data['role'] as List<dynamic>?)?.join(', ') ??
                'Tidak ada role',
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading accounts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar akun: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin - Pembuat Akun'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAccounts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form Section
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Buat Akun Baru',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Nama Lengkap',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Nama tidak boleh kosong';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.email),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email tidak boleh kosong';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Email tidak valid';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.lock),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password tidak boleh kosong';
                                  }
                                  if (value.length < 6) {
                                    return 'Password minimal 6 karakter';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedRole,
                                decoration: InputDecoration(
                                  labelText: 'Role',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.badge),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'admin_penyemaian',
                                    child: Text('Admin Penyemaian'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'admin_tpk',
                                    child: Text('Admin TPK'),
                                  ),
                                ],
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedRole = newValue;
                                    });
                                  }
                                },
                              ),
                              SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _createAccount,
                                    icon: Icon(Icons.add),
                                    label: Text('Buat Akun'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _generateDummyAccounts,
                                    icon: Icon(Icons.bolt),
                                    label: Text('Generate Dummy Accounts'),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Accounts List Section
                    Text(
                      'Daftar Akun',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    _accounts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'Belum ada akun yang terdaftar',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: _accounts.length,
                            itemBuilder: (context, index) {
                              final account = _accounts[index];
                              return Card(
                                margin: EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Icon(
                                      account['role']
                                              .toString()
                                              .contains('admin_penyemaian')
                                          ? Icons.eco
                                          : Icons.forest,
                                    ),
                                  ),
                                  title: Text(account['nama_lengkap']),
                                  subtitle: Text(account['email']),
                                  trailing: Chip(
                                    label: Text(
                                      account['role']
                                              .toString()
                                              .contains('admin_penyemaian')
                                          ? 'Admin Penyemaian'
                                          : 'Admin TPK',
                                    ),
                                    backgroundColor: account['role']
                                            .toString()
                                            .contains('admin_penyemaian')
                                        ? Colors.green[100]
                                        : Colors.brown[100],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}



// Cara Mengakses Halaman Admin:
// 1. Tambahkan menu khusus untuk Super Admin di halaman login atau di drawer menu
// 2. Contoh tombol atau menu item:

/*
ElevatedButton(
  onPressed: () => Get.toNamed('/admin/account-creator'),
  child: Text('Halaman Admin'),
),
*/

// atau di drawer menu:

/*
ListTile(
  leading: Icon(Icons.admin_panel_settings),
  title: Text('Admin Tools'),
  onTap: () => Get.toNamed('/admin/account-creator'),
),
*/