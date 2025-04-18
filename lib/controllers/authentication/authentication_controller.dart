import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';
import 'package:flutter_green_track/data/models/user_model.dart';
import 'package:flutter_green_track/data/repositories/authentication_repository.dart';
import 'package:flutter_green_track/fitur/navigation/navigation_page.dart';
import 'package:flutter_green_track/service/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

enum LoginStatus { initial, loading, success, failure }

class AuthenticationController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();

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

  // Handle forgot password
  void forgotPassword() {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar(
        'Error',
        'Masukkan email Anda terlebih dahulu',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
      return;
    }

    // Send password reset email
    FirebaseAuth.instance.sendPasswordResetEmail(email: email).then((_) {
      Get.snackbar(
        'Lupa Password',
        'Link reset password telah dikirim ke email Anda',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
        duration: Duration(seconds: 3),
      );
    }).catchError((error) {
      Get.snackbar(
        'Error',
        'Gagal mengirim link reset password: ${error.message}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    });
  }

  // Navigate based on user role
  void _navigateBasedOnRole(UserRole role) {
    Get.offAll(() => MainNavigationContainer(userRole: role));
  }
}
