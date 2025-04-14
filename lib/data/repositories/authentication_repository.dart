import 'package:flutter_green_track/fitur/dashboard_tpk/dashboard_tpk_page.dart';

import '../models/authentication_model.dart';
import '../services/authentication_service.dart';

import 'dart:convert';
import 'package:flutter_green_track/data/models/user_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_green_track/data/models/user_model.dart';

class AuthenticationRepository {
  final String _userKey = 'current_user';

  // Get current logged in user
  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString(_userKey);

      if (userString == null) return null;

      final userJson = json.decode(userString);
      return UserModel.fromJson(userJson);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Save user to storage
  Future<void> setCurrentUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = json.encode(user.toJson());

      await prefs.setString(_userKey, userString);
    } catch (e) {
      print('Error setting current user: $e');
      throw Exception('Failed to save user data');
    }
  }

  // Clear user from storage (logout)
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      print('Error during logout: $e');
      throw Exception('Failed to logout');
    }
  }

  // Example of a login API call method
  Future<UserModel> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      // This would be an API call in a real app
      // For demo, we'll just create a user based on email
      await Future.delayed(
          Duration(milliseconds: 800)); // Simulate network delay

      // Determine role based on email for demo purposes
      final UserRole role = email.contains('penyemaian')
          ? UserRole.adminPenyemaian
          : UserRole.adminTPK;

      // Create a mock user
      final user = UserModel(
        id: '1',
        name: email.split('@')[0],
        email: email,
        role: role,
        photoUrl: '',
      );

      // Store user in local storage
      await setCurrentUser(user);

      return user;
    } catch (e) {
      print('Login API error: $e');
      throw Exception('Failed to login');
    }
  }
}
