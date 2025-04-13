import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';

/// Halaman untuk membuat admin dummy
/// PENTING: Halaman ini hanya untuk pengembangan dan sebaiknya dihapus di build production
class AdminGeneratorPage extends StatefulWidget {
  static String routeName = '/admin-generator';

  @override
  _AdminGeneratorPageState createState() => _AdminGeneratorPageState();
}

class _AdminGeneratorPageState extends State<AdminGeneratorPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = 'adminTPK';
  bool _isLoading = false;
  bool _showPassword = false;

  List<Map<String, dynamic>> _createdAdmins = [];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Generator'),
        backgroundColor: Color(0xFF4CAF50),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Warning banner
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[700]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber[800]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Halaman ini hanya untuk pengembangan. Hapus sebelum rilis produksi!',
                        style: TextStyle(color: Colors.amber[900]),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Form untuk membuat admin
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Buat Admin Baru',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Nama Admin
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Admin',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama wajib diisi';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16),

                    // Email Admin
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Admin',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email wajib diisi';
                        }
                        if (!GetUtils.isEmail(value)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16),

                    // Password Admin
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: 'Password Admin',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16),

                    // Pilihan Role
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedRole,
                          items: [
                            DropdownMenuItem(
                              value: 'adminTPK',
                              child: Text('Admin TPK'),
                            ),
                            DropdownMenuItem(
                              value: 'adminPenyemaian',
                              child: Text('Admin Penyemaian'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Tombol Submit
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _handleCreateAdmin,
                      icon: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Icon(Icons.add),
                      label: Text(_isLoading ? 'Processing...' : 'Buat Admin'),
                    ),

                    SizedBox(height: 16),

                    // Tombol Generate Multiple Admin (untuk testing)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF81C784),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _generateMultipleAdmins,
                      icon: Icon(Icons.group_add),
                      label: Text('Generate 5 Admin Random'),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Admin yang dibuat'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              SizedBox(height: 16),

              // Daftar admin yang dibuat
              _createdAdmins.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada admin yang dibuat',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : Column(
                      children: _createdAdmins.map((admin) {
                        return Card(
                          margin: EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: admin['role'] == 'adminTPK'
                                  ? Colors.amber[100]
                                  : Colors.green[100],
                              foregroundColor: admin['role'] == 'adminTPK'
                                  ? Colors.amber[800]
                                  : Colors.green[800],
                              child: admin['role'] == 'adminTPK'
                                  ? Icon(Icons.forest)
                                  : Icon(Icons.eco),
                            ),
                            title: Text(admin['name']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(admin['email']),
                                Text(
                                  admin['role'] == 'adminTPK'
                                      ? 'Admin TPK'
                                      : 'Admin Penyemaian',
                                  style: TextStyle(
                                    color: admin['role'] == 'adminTPK'
                                        ? Colors.amber[800]
                                        : Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              'Password: ${admin['password']}',
                              style: TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi untuk membuat admin baru
  Future<void> _handleCreateAdmin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Buat user di Firebase Auth
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Tambahkan data admin ke Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // 3. Tambahkan ke list admin yang berhasil dibuat
      setState(() {
        _createdAdmins.add({
          'uid': userCredential.user!.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'role': _selectedRole,
        });
      });

      // 4. Reset form
      _formKey.currentState!.reset();
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();

      // 5. Tampilkan pesan sukses
      Get.snackbar(
        'Berhasil',
        'Admin berhasil dibuat',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error creating admin: $e');

      // Tampilkan pesan error
      Get.snackbar(
        'Error',
        'Gagal membuat admin: ${e.toString()}',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk generate multiple admin secara random
  Future<void> _generateMultipleAdmins() async {
    setState(() {
      _isLoading = true;
    });

    try {
      for (int i = 0; i < 5; i++) {
        // Generate random data
        final String role = i % 2 == 0 ? 'adminTPK' : 'adminPenyemaian';
        final String name = role == 'adminTPK'
            ? 'Admin TPK ${_getRandomString(3).toUpperCase()}'
            : 'Admin Penyemaian ${_getRandomString(3).toUpperCase()}';
        final String email =
            '${role.toLowerCase()}_${_getRandomString(5)}@example.com';
        final String password = 'password${_getRandomString(4)}';

        // Buat user di Firebase Auth
        final UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Tambahkan data admin ke Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name': name,
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });

        // Tambahkan ke list admin yang berhasil dibuat
        setState(() {
          _createdAdmins.add({
            'uid': userCredential.user!.uid,
            'name': name,
            'email': email,
            'password': password,
            'role': role,
          });
        });

        // Delay sedikit untuk menghindari rate limiting
        await Future.delayed(Duration(milliseconds: 500));
      }

      // Tampilkan pesan sukses
      Get.snackbar(
        'Berhasil',
        '5 Admin random berhasil dibuat',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error generating multiple admins: $e');

      // Tampilkan pesan error
      Get.snackbar(
        'Error',
        'Gagal membuat admin: ${e.toString()}',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fungsi helper untuk generate string random
  String _getRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch.toString();

    String result = '';
    for (int i = 0; i < length; i++) {
      result +=
          chars[(random.codeUnitAt(i % random.length) + i) % chars.length];
    }

    return result;
  }
}
