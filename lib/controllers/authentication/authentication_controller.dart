import 'package:flutter/material.dart';
import 'package:flutter_green_track/data/models/user_model.dart';
import 'package:flutter_green_track/data/repositories/authentication_repository.dart';
import 'package:flutter_green_track/fitur/navigation/navigation_page.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

enum LoginStatus { initial, loading, success, failure }

class AuthenticationController extends GetxController {
  final AuthenticationRepository repository = AuthenticationRepository();

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
      final user = await repository.getCurrentUser();
      if (user != null) {
        currentUser.value = user;
        // Navigate based on role if already logged in
        _navigateBasedOnRole(user.role);
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

      // In a real app, this would be an API call to login
      // For demo, we'll just simulate a login based on email
      await Future.delayed(
          Duration(milliseconds: 800)); // Simulate network delay

      UserRole role;

      // Determine role based on email
      if (email.contains('penyemaian')) {
        role = UserRole.adminPenyemaian;
      } else {
        role = UserRole.adminTPK;
      }

      // Create a mock user
      final user = UserModel(
        id: '1',
        name: email.split('@')[0],
        email: email,
        role: role,
        photoUrl: '',
      );

      // Store user in repository
      await repository.setCurrentUser(user);

      // Update current user
      currentUser.value = user;

      // Login successful
      loginStatus.value = LoginStatus.success;

      // Navigate based on role
      _navigateBasedOnRole(role);
    } catch (e) {
      loginStatus.value = LoginStatus.failure;
      errorMessage.value = 'Login gagal: ${e.toString()}';
      print('Login error: $e');
    }
  }

  // Handle logout
  Future<void> logout() async {
    try {
      await repository.logout();
      currentUser.value = null;
      resetForm();
      Get.offAllNamed('/login'); // Navigate back to login screen
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // Handle forgot password
  void forgotPassword() {
    // Implement password recovery logic
    print('Forgot password requested for: ${emailController.text}');
    // For demo, just show a snackbar
    Get.snackbar(
      'Lupa Password',
      'Link reset password telah dikirim ke email Anda',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green[100],
      colorText: Colors.green[800],
      duration: Duration(seconds: 3),
    );
  }

  // Navigate based on user role
  void _navigateBasedOnRole(UserRole role) {
    Get.offAll(() => MainNavigationContainer(userRole: role));
  }
}
