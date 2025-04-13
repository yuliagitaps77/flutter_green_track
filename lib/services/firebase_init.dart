import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';

// Initialize Firebase and setup controllers
class FirebaseInitializer {
  static Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      print('Firebase initialized successfully');

      // Initialize AuthController as a global controller
      Get.put<AuthController>(AuthController(), permanent: true);
    } catch (e) {
      print('Error initializing Firebase: $e');
      // Display error message to user
      Get.snackbar(
        'Error',
        'Failed to connect to the server. Please check your internet connection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
    }
  }
}
