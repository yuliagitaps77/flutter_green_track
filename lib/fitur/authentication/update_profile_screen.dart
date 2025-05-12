import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileUpdateScreen extends StatefulWidget {
  static String routeName = "/profile-update";

  const ProfileUpdateScreen({Key? key}) : super(key: key);

  @override
  _ProfileUpdateScreenState createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  final AuthenticationController _authController =
      Get.find<AuthenticationController>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  File? _selectedImage;
  bool _isUploading = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with current user data
    final user = _authController.currentUser.value;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengambil gambar: ${e.toString()}';
      });
    }
  }

  Future<void> _updateProfile() async {
    // Validate name field
    Get.snackbar(
      'Sukses',
      'Profil berhasil diperbarui',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Nama tidak boleh kosong';
      });
      return;
    }

    try {
      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      final currentUser = _authController.currentUser.value;
      if (currentUser == null) {
        throw Exception('User tidak ditemukan');
      }

      // Upload image if selected
      String? photoUrl = currentUser.photoUrl;
      if (_selectedImage != null) {
        setState(() {
          _isUploading = true;
        });

        photoUrl = await _authController
            .uploadImageToFreeImageHost(_selectedImage!.path);

        setState(() {
          _isUploading = false;
        });

        if (photoUrl == null) {
          throw Exception('Gagal mengunggah foto profil');
        }
      }

      // Update profile in Firestore
      await _authController.updateUserProfile(
        name: _nameController.text.trim(),
        photoUrl: photoUrl,
      );

      Get.snackbar(
        'Sukses',
        'Profil berhasil diperbarui',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.back();
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memperbarui profil: ${e.toString()}';
        _isSaving = false;
      });
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    try {
      final user = _authController.currentUser.value;
      if (user == null) {
        throw Exception('User tidak ditemukan');
      }

      await _authController.resetPassword(user.email);

      Get.snackbar(
        'Sukses',
        'Tautan reset password telah dikirim ke email Anda',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Update Profil',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile photo section
              Center(
                child: Stack(
                  children: [
                    Obx(() {
                      final user = _authController.currentUser.value;
                      final radius = 60.0;

                      // If there's a selected image, show it
                      if (_selectedImage != null) {
                        return CircleAvatar(
                          radius: radius,
                          backgroundImage: FileImage(_selectedImage!),
                        );
                      }
                      // If there's an existing photo URL, show it
                      else if (user?.photoUrl != null &&
                          user!.photoUrl!.isNotEmpty) {
                        return CircleAvatar(
                          radius: radius,
                          backgroundImage: NetworkImage(user.photoUrl!),
                          onBackgroundImageError: (_, __) {
                            // Handle image loading error
                          },
                        );
                      }
                      // Otherwise show a placeholder with initials
                      else {
                        return CircleAvatar(
                          radius: radius,
                          backgroundColor: Color(0xFF4CAF50),
                          child: Text(
                            user?.name.isNotEmpty == true
                                ? user!.name
                                    .substring(0, min(2, user.name.length))
                                    .toUpperCase()
                                : "?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                    }),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploading ? null : _pickImage,
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: _isUploading
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // Form fields
              Text(
                'Nama Lengkap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Masukkan nama lengkap',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFF4CAF50)),
                  ),
                  prefixIcon:
                      Icon(Icons.person_outline, color: Color(0xFF4CAF50)),
                ),
              ),

              SizedBox(height: 20),

              Text(
                'Email',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              SizedBox(height: 8),
              Obx(() {
                final user = _authController.currentUser.value;
                return TextField(
                  controller: _emailController,
                  enabled: false, // Email cannot be changed
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
                  ),
                );
              }),

              SizedBox(height: 20),

              // User role display (read-only)
              Text(
                'Role Pengguna',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              SizedBox(height: 8),
              Obx(() {
                final role = _authController.currentUser.value?.role;
                return Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          role == UserRole.adminPenyemaian
                              ? 'Admin Penyemaian'
                              : 'Admin TPK',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.lock_outline,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
                );
              }),

              SizedBox(height: 15),

              // Password reset section
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Klik tombol di bawah untuk mengirim tautan reset password ke email Anda.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CAF50),
                        minimumSize: Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _sendPasswordResetEmail,
                      icon: Icon(Icons.lock_reset, color: Colors.white),
                      label: Text(
                        'Kirim Tautan Reset Password',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 30),

              // Update button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isSaving ? null : _updateProfile,
                child: _isUploading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Menyimpan...'),
                        ],
                      )
                    : Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to get minimum of two numbers
  int min(int a, int b) {
    return a < b ? a : b;
  }
}
