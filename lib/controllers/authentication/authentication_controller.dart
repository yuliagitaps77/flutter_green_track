import 'package:get/get.dart';
import '../../data/repositories/authentication_repository.dart';
import '../../data/models/authentication_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_green_track/fitur/navigation/navigation_page.dart';

enum UserRole {
  adminPenyemaian,
  adminTPK,
}

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable variables
  final Rx<User?> firebaseUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final Rx<UserRole?> userRole = Rx<UserRole>(UserRole.adminTPK);

  // User data
  final RxMap<String, dynamic> userData = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to authentication state changes
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _setInitialScreen);
  }

  // Determine which screen to show based on auth state
  void _setInitialScreen(User? user) async {
    if (user == null) {
      // User is not logged in, go to login screen
      Get.offAllNamed('/login');
    } else {
      // User is logged in, fetch user data and determine role
      isLoading.value = true;
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          userData.value = userDoc.data() as Map<String, dynamic>;

          // Set user role based on Firestore data
          if (userData['role'] == 'adminPenyemaian') {
            userRole.value = UserRole.adminPenyemaian;
          } else {
            userRole.value = UserRole.adminTPK;
          }

          // Navigate to the appropriate screen
          Get.offAll(() => MainNavigationContainer(
                userRole: userRole.value,
              ));
        } else {
          // User document doesn't exist in Firestore
          await _auth.signOut();
          Get.offAllNamed('/login');
          Get.snackbar(
              'Error', 'User data not found. Please contact administrator.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white);
        }
      } catch (e) {
        print('Error fetching user data: $e');
        Get.snackbar('Error', 'Failed to load user data. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      } finally {
        isLoading.value = false;
      }
    }
  }

  // Login method
  Future<bool> login(String email, String password) async {
    isLoading.value = true;
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Wrong password.';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        case 'user-disabled':
          message = 'This user has been disabled.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }

      Get.snackbar('Login Failed', message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return false;
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Logout method
  Future<void> logout() async {
    isLoading.value = true;
    try {
      await _auth.signOut();
      userData.clear();
    } catch (e) {
      Get.snackbar('Error', 'Failed to log out.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    isLoading.value = true;
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      Get.snackbar('Success', 'Password reset email sent. Check your inbox.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
      return true;
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found with this email.';
      } else {
        message = 'Failed to send reset email. Try again later.';
      }

      Get.snackbar('Error', message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;
}
