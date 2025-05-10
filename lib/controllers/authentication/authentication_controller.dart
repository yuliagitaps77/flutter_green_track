import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';
import 'package:flutter_green_track/data/models/user_model.dart';
import 'package:flutter_green_track/data/repositories/authentication_repository.dart';
import 'package:flutter_green_track/fitur/authentication/reset_password_screen.dart';
import 'package:flutter_green_track/fitur/navigation/navigation_page.dart';
import 'package:flutter_green_track/service/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart' as http;

enum LoginStatus { initial, loading, success, failure }

class AuthenticationController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  Future<String?> uploadImageToFreeImageHost(String imagePath) async {
    try {
      final apiKey = '6d207e02198a847aa98d0a2a901485a5';
      final url = Uri.parse('https://freeimage.host/api/1/upload');

      final imageBytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        url,
        body: {
          'key': apiKey,
          'source': base64Image,
          'format': 'json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final imageUrl = jsonResponse['image']['url'];
        return imageUrl;
      } else {
        print('Upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

// Update user profile
  final RxBool _userProfileUpdated = false.obs;

// Add this update to your updateUserProfile method
  Future<void> updateUserProfile({
    required String name,
    String? photoUrl,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Prepare update data
      final Map<String, dynamic> updateData = {
        'nama_lengkap': name,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Add photo URL if provided
      if (photoUrl != null) {
        updateData['photo_url'] = photoUrl;
      }

      // Update user data in Firestore
      await FirebaseFirestore.instance
          .collection('akun')
          .doc(user.uid)
          .update(updateData);

      // Update local user model
      final updatedUser = currentUser.value!;
      currentUser.value = UserModel(
        id: updatedUser.id,
        email: updatedUser.email,
        name: name,
        role: updatedUser.role,
        photoUrl: photoUrl ?? updatedUser.photoUrl,
        lastLogin: updatedUser.lastLogin,
        kodeOtp: updatedUser.kodeOtp,
        createdAt: updatedUser.createdAt,
        updatedAt: Timestamp.now(),
      );

      // Save updated user to local storage
      await _firebaseService.saveUserLocally(currentUser.value!);

      // Notify other controllers that user profile has been updated
      // This is the key change to enable real-time updates
      _userProfileUpdated.toggle();

      print('User profile updated successfully. Name: $name, Photo: $photoUrl');
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

// 2. Add a method that other controllers can call to check if they need to refresh
  bool hasUserProfileBeenUpdated(DateTime since) {
    // Called by other controllers to check if they need to refresh their user data
    return _userProfileUpdated.value;
  }

// 3. Add method to refresh the current user from Firestore
  Future<void> refreshCurrentUserFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await _firebaseService.getUserData(user.uid);
        if (userData != null) {
          // Update current user
          currentUser.value = userData;
          // Save to local storage
          await _firebaseService.saveUserLocally(userData);
          print('User profile refreshed from Firestore');
        }
      }
    } catch (e) {
      print('Error refreshing user profile: $e');
    }
  }

  // Observable variables for form fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Observable for password visibility toggle
  final RxBool isPasswordVisible = false.obs;

  // Observable for login status
  final Rx<LoginStatus> loginStatus = LoginStatus.initial.obs;

  // Observable for error message
  final RxString errorMessage = ''.obs;

  // Observable for current user
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    checkLoggedInStatus();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  // Check if user is already logged in
  Future<void> checkLoggedInStatus() async {
    try {
      // Check local storage first
      final localUser = await _firebaseService.getLocalUser();
      if (localUser != null) {
        currentUser.value = localUser;
        // Navigate based on role if already logged in
        _navigateBasedOnRole(localUser.role);
        return;
      }

      // Check Firebase Auth
      final firebaseUser = _firebaseService.getCurrentFirebaseUser();
      if (firebaseUser != null) {
        // Get user details from Firestore
        final userData = await _firebaseService.getUserData(firebaseUser.uid);
        if (userData != null) {
          currentUser.value = userData;
          // Save user to local storage
          await _firebaseService.saveUserLocally(userData);
          // Navigate based on role
          _navigateBasedOnRole(userData.role);
        }
      }
    } catch (e) {
      print('Error checking login status: $e');
    }
  }

  // Reset form
  void resetForm() {
    emailController.clear();
    passwordController.clear();
    errorMessage.value = '';
    loginStatus.value = LoginStatus.initial;
  }
// Tambahkan method ini ke AuthenticationController

// Improved reset password method
  Future<void> resetPassword(String email) async {
    if (email.isEmpty) {
      throw Exception('Email tidak boleh kosong');
    }

    try {
      // Send password reset email via Firebase
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Return success (no exception means success)
      return;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'user-not-found':
          throw Exception('Email tidak terdaftar');
        case 'invalid-email':
          throw Exception('Format email tidak valid');
        default:
          throw Exception(e.message ?? 'Terjadi kesalahan saat reset password');
      }
    } catch (e) {
      // Handle other errors
      throw Exception('Terjadi kesalahanforgotPassword: ${e.toString()}');
    }
  }

  // Handle login
  Future<void> login() async {
    // Don't attempt login if already in process
    if (loginStatus.value == LoginStatus.loading) return;

    // Basic validation
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      errorMessage.value = 'Email dan password tidak boleh kosong';
      return;
    }

    try {
      loginStatus.value = LoginStatus.loading;

      // Authenticate with Firebase
      final userCredential = await _firebaseService.signInWithEmailAndPassword(
        email,
        password,
      );

      if (userCredential.user != null) {
        // Get user data from Firestore
        final userData =
            await _firebaseService.getUserData(userCredential.user!.uid);

        if (userData != null) {
          // Save user locally
          await _firebaseService.saveUserLocally(userData);

          // Update current user
          currentUser.value = userData;

          // Login successful
          loginStatus.value = LoginStatus.success;

          // Navigate based on role
          _navigateBasedOnRole(userData.role);
        } else {
          // User exists in Auth but not in Firestore
          throw Exception('User data not found');
        }
      }
    } on FirebaseAuthException catch (e) {
      loginStatus.value = LoginStatus.failure;

      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'user-not-found':
          errorMessage.value = 'Email tidak terdaftar';
          break;
        case 'wrong-password':
          errorMessage.value = 'Password salah';
          break;
        case 'invalid-credential':
          errorMessage.value = 'Email atau password salah';
          break;
        default:
          errorMessage.value = 'Login gagal: ${e.message}';
      }
      print('Login error: ${e.code} - ${e.message}');
    } catch (e) {
      loginStatus.value = LoginStatus.failure;
      errorMessage.value = 'Login gagal: ${e.toString()}';
      print('Login error: $e');
    }
  }

  // Handle logout
  Future<void> logout() async {
    try {
      // Sign out from Firebase
      await _firebaseService.signOut();

      // Clear local storage
      await _firebaseService.removeLocalUser();

      // Reset user state
      currentUser.value = null;
      resetForm();

      // Navigate back to login screen
      Get.offAllNamed('/login');
    } catch (e) {
      print('Logout error: $e');
    }
  }

// Modify the existing forgotPassword method
  void forgotPassword() {
    // Navigate to Reset Password screen instead of immediately sending email
    final email = emailController.text.trim();
    // Optionally pre-fill the email on the reset password screen
    Get.toNamed(ResetPasswordScreen.routeName);
  }

  // Navigate based on user role
  void _navigateBasedOnRole(UserRole role) {
    Get.offAll(() => MainNavigationContainer(userRole: role));
  }
}
