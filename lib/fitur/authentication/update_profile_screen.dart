import 'dart:io';
import 'dart:math';
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
  bool _isResettingPassword = false;
  bool _resetLinkSent = false;

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
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Nama lengkap tidak boleh kosong';
      });
      Get.snackbar(
        'Validasi',
        'Nama lengkap tidak boleh kosong',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(10),
        borderRadius: 10,
        icon: Icon(Icons.error_outline, color: Colors.white),
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        forwardAnimationCurve: Curves.easeOutBack,
      );
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

      setState(() {
        _isSaving = false;
      });

      // Show success snackbar
      Get.snackbar(
        'Sukses',
        'Profil berhasil diperbarui',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
        margin: EdgeInsets.all(10),
        borderRadius: 10,
        icon: Icon(Icons.check_circle_outline, color: Colors.white),
        shouldIconPulse: true,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        forwardAnimationCurve: Curves.easeOutBack,
        mainButton: TextButton(
          onPressed: () {
            Get.back();
            Future.delayed(Duration(milliseconds: 500), () {
              Get.back();
            });
          },
          child: Text(
            'OK',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memperbarui profil: ${e.toString()}';
        _isSaving = false;
        _isUploading = false;
      });

      // Show error snackbar
      Get.snackbar(
        'Error',
        'Gagal memperbarui profil: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(10),
        borderRadius: 10,
        icon: Icon(Icons.error_outline, color: Colors.white),
        shouldIconPulse: true,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        forwardAnimationCurve: Curves.easeOutBack,
        mainButton: TextButton(
          onPressed: () => Get.back(),
          child: Text(
            'OK',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    try {
      setState(() {
        _isResettingPassword = true;
        _errorMessage = null;
      });

      final user = _authController.currentUser.value;
      if (user == null) {
        throw Exception('User tidak ditemukan');
      }

      await _authController.resetPassword(user.email);

      setState(() {
        _resetLinkSent = true;
        _isResettingPassword = false;
      });

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
        _isResettingPassword = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Update Profil',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFF5F9F5),
              Color(0xFFEDF7ED),
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
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
                                fontFamily: 'Poppins',
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
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
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
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF424242),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama lengkap',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Poppins',
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
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
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 8),
                Obx(() {
                  final user = _authController.currentUser.value;
                  return TextField(
                    controller: _emailController,
                    enabled: false,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF424242),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      prefixIcon:
                          Icon(Icons.email_outlined, color: Colors.grey),
                    ),
                  );
                }),

                SizedBox(height: 20),

                Text(
                  'Role Pengguna',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 8),
                Obx(() {
                  final role = _authController.currentUser.value?.role;
                  return Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          color: Color(0xFF4CAF50),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            role == UserRole.adminPenyemaian
                                ? 'Admin Penyemaian'
                                : 'Admin TPK',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF424242),
                              fontFamily: 'Poppins',
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

                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: _resetLinkSent ? Color(0xFFE8F5E9) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                    border: _resetLinkSent
                        ? Border.all(color: Color(0xFF4CAF50))
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _resetLinkSent
                                ? Icons.check_circle_outline
                                : Icons.lock_outline,
                            color: _resetLinkSent
                                ? Color(0xFF4CAF50)
                                : Color(0xFF2E7D32),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        _resetLinkSent
                            ? 'Tautan reset password telah dikirim ke email Anda. Silakan cek email Anda untuk melanjutkan.'
                            : 'Klik tombol di bawah untuk mengirim tautan reset password ke email Anda.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF424242),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _resetLinkSent
                              ? Color(0xFF66BB6A)
                              : Color(0xFF4CAF50),
                          minimumSize: Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isResettingPassword
                            ? null
                            : _resetLinkSent
                                ? null
                                : _sendPasswordResetEmail,
                        icon: _isResettingPassword
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Icon(
                                _resetLinkSent ? Icons.check : Icons.lock_reset,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isResettingPassword
                              ? 'Mengirim...'
                              : _resetLinkSent
                                  ? 'Tautan Terkirim'
                                  : 'Kirim Tautan Reset Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 30),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  onPressed:
                      (_isSaving || _isUploading) ? null : _updateProfile,
                  child: (_isSaving || _isUploading)
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
                            Text(
                              'Menyimpan...',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ],
            ),
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
