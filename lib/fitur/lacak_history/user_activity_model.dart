import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_green_track/controllers/authentication/authentication_controller.dart';
import 'package:flutter_green_track/controllers/dashboard_pneyemaian/dashboard_penyemaian_controller.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
// Tambahkan pada file yang sama dengan UserActivity atau buat file baru

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_green_track/data/models/user_model.dart';

class FirestoreActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference untuk activities
  CollectionReference get _activitiesCollection =>
      _firestore.collection('activities');

  // Mencatat aktivitas ke Firestore
  Future<void> recordActivityToFirestore(
      UserActivity activity, UserModel user) async {
    try {
      // Tambahkan data user ke dalam metadata jika belum ada
      Map<String, dynamic> metadata = activity.metadata ?? {};

      // Tambahkan informasi user
      metadata['userName'] = user.name;
      metadata['userEmail'] = user.email;
      metadata['userPhotoUrl'] = user.photoUrl;

      // Prepare data for Firestore
      Map<String, dynamic> activityData = {
        'id': activity.id,
        'userId': activity.userId,
        'userName': user.name, // Tambahkan nama user
        'userRole': activity.userRole,
        'activityType': activity.activityType,
        'description': activity.description,
        'targetId': activity.targetId,
        'icon': activity.icon,
        'metadata': metadata,
        'timestamp': Timestamp.fromDate(activity.timestamp),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Simpan ke Firestore dengan ID aktivitas sebagai document ID
      await _activitiesCollection.doc(activity.id).set(activityData);
    } catch (e) {
      print('Error recording activity to Firestore: $e');
      // Biarkan operasi lokal tetap berjalan meskipun ada error Firestore
    }
  }

  // Mengambil aktivitas dari Firestore berdasarkan user ID
  Future<List<UserActivity>> getActivitiesForUserFromFirestore(String userId,
      {int limit = 20}) async {
    try {
      final QuerySnapshot snapshot = await _activitiesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Konversi Timestamp ke DateTime
        DateTime timestamp;
        if (data['timestamp'] is Timestamp) {
          timestamp = (data['timestamp'] as Timestamp).toDate();
        } else {
          timestamp = DateTime.now(); // Fallback
        }

        return UserActivity(
          id: data['id'],
          userId: data['userId'],
          userRole: data['userRole'],
          activityType: data['activityType'],
          description: data['description'],
          targetId: data['targetId'],
          icon: data['icon'],
          metadata: data['metadata'],
          timestamp: timestamp,
        );
      }).toList();
    } catch (e) {
      print('Error getting activities from Firestore: $e');
      return [];
    }
  }

  // Mengambil aktivitas terbaru dari Firestore (global untuk semua pengguna)
  Future<List<UserActivity>> getRecentActivitiesFromFirestore(
      {int limit = 20}) async {
    try {
      final QuerySnapshot snapshot = await _activitiesCollection
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Konversi Timestamp ke DateTime
        DateTime timestamp;
        if (data['timestamp'] is Timestamp) {
          timestamp = (data['timestamp'] as Timestamp).toDate();
        } else {
          timestamp = DateTime.now(); // Fallback
        }

        return UserActivity(
          id: data['id'],
          userId: data['userId'],
          userRole: data['userRole'],
          activityType: data['activityType'],
          description: data['description'],
          targetId: data['targetId'],
          icon: data['icon'],
          metadata: data['metadata'],
          timestamp: timestamp,
        );
      }).toList();
    } catch (e) {
      print('Error getting recent activities from Firestore: $e');
      return [];
    }
  }
}

// Model for user activity records
class UserActivity {
  final String id;
  final String userId;
  final String userRole;
  final String activityType;
  final String description;
  final String?
      targetId; // ID of the object being affected (bibit ID, kayu ID, etc.)
  final String? icon; // Icon for this activity type
  final Map<String, dynamic>?
      metadata; // Additional data specific to the activity
  final DateTime timestamp;

  UserActivity({
    required this.id,
    required this.userId,
    required this.userRole,
    required this.activityType,
    required this.description,
    this.targetId,
    this.icon,
    this.metadata,
    required this.timestamp,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userRole': userRole,
      'activityType': activityType,
      'description': description,
      'targetId': targetId,
      'icon': icon,
      'metadata': metadata,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // Create from JSON (for retrieval)
  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id'],
      userId: json['userId'],
      userRole: json['userRole'],
      activityType: json['activityType'],
      description: json['description'],
      targetId: json['targetId'],
      icon: json['icon'],
      metadata: json['metadata'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
}

// Activity types enum for consistency
class ActivityTypes {
  // Admin Penyemaian activities
  static const String scanBarcode = 'SCAN_BARCODE';
  static const String printBarcode = 'PRINT_BARCODE';
  static const String updateBibit = 'UPDATE_BIBIT';
  static const String deleteBibit = 'DELETE_BIBIT';
  static const String addJadwalRawat = 'ADD_JADWAL_RAWAT';

  // Admin TPK activities
  static const String updateKayu = 'UPDATE_KAYU';
  static const String deleteKayu = 'DELETE_KAYU';
  static const String addPengiriman = 'ADD_PENGIRIMAN';
}

class AppController extends GetxController {
  static AppController get to => Get.find();

  // Observable list of recent activities
  final recentActivities = <UserActivity>[].obs;

  // Maximum number of activities to store locally
  final int maxStoredActivities = 100;

  // Storage key for activities
  final String storageKey = 'user_activities';

  // Current user
  late final Rx<UserModel?> currentUser;

  // Firestore Activity Service
  final FirestoreActivityService _firestoreActivityService =
      FirestoreActivityService();

  @override
  void onInit() {
    super.onInit();

    // Get user from auth controller
    final authController = Get.find<AuthenticationController>();
    currentUser = authController.currentUser;

    // Load stored activities
    loadActivities();
  }

  // Load activities from local storage
  Future<void> loadActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedActivities = prefs.getStringList(storageKey) ?? [];

      final List<UserActivity> activities = [];
      for (var activityJson in storedActivities) {
        try {
          final Map<String, dynamic> activityMap = jsonDecode(activityJson);
          activities.add(UserActivity.fromJson(activityMap));
        } catch (e) {
          print('Error parsing activity: $e');
        }
      }

      // Sort by timestamp (newest first)
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Update observable list
      recentActivities.assignAll(activities);
    } catch (e) {
      print('Error loading activities: $e');
    }
  }

  // Save activities to local storage
  Future<void> saveActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert to JSON strings
      final List<String> activityJsonList = recentActivities
          .map((activity) => jsonEncode(activity.toJson()))
          .toList();

      // Save to storage
      await prefs.setStringList(storageKey, activityJsonList);
    } catch (e) {
      print('Error saving activities: $e');
    }
  }

  // Record a new activity
  Future<void> recordActivity({
    required String activityType,
    required String description,
    String? targetId,
    Map<String, dynamic>? metadata,
  }) async {
    // Ensure user is logged in
    if (currentUser.value == null) return;

    // Create activity record
    final activity = UserActivity(
      id: const Uuid().v4(),
      userId: currentUser.value!.id,
      userRole: currentUser.value!.role.toString(),
      activityType: activityType,
      description: description,
      targetId: targetId,
      // Get icon based on activity type
      icon: _getIconForActivityType(activityType),
      metadata: metadata,
      timestamp: DateTime.now(),
    );

    // Add to list (at the beginning)
    recentActivities.insert(0, activity);

    // Trim list if it exceeds maximum
    if (recentActivities.length > maxStoredActivities) {
      recentActivities.removeRange(
          maxStoredActivities, recentActivities.length);
    }

    // Save to local storage
    await saveActivities();

    // Save to Firestore jika user sudah login
    if (currentUser.value != null) {
      await _firestoreActivityService.recordActivityToFirestore(
          activity, currentUser.value!);
    }
  }

  // Helper method to get icon for activity type
  String? _getIconForActivityType(String activityType) {
    final Map<String, String> activityIcons = {
      ActivityTypes.scanBarcode: 'Icons.qr_code_scanner_rounded',
      ActivityTypes.printBarcode: 'Icons.print_rounded',
      ActivityTypes.updateBibit: 'Icons.edit',
      ActivityTypes.deleteBibit: 'Icons.delete',
      ActivityTypes.addJadwalRawat: 'Icons.calendar_month_rounded',
      ActivityTypes.updateKayu: 'Icons.edit',
      ActivityTypes.deleteKayu: 'Icons.delete',
      ActivityTypes.addPengiriman: 'Icons.local_shipping_rounded',
    };

    return activityIcons[activityType];
  }

  // Get activity records for a specific user
  List<UserActivity> getActivitiesForUser(String userId) {
    return recentActivities
        .where((activity) => activity.userId == userId)
        .toList();
  }

  // Get recent activities (with limit)
  List<UserActivity> getRecentActivities({int limit = 10}) {
    return recentActivities.take(limit).toList();
  }

  // Sync activities from Firestore
  Future<void> syncActivitiesFromFirestore({int limit = 20}) async {
    if (currentUser.value == null) return;

    try {
      // Get user activities from Firestore
      final firestoreActivities = await _firestoreActivityService
          .getActivitiesForUserFromFirestore(currentUser.value!.id,
              limit: limit);

      if (firestoreActivities.isNotEmpty) {
        // Merge with local activities (avoid duplicates by ID)
        final Map<String, UserActivity> activityMap = {};

        // Add local activities to map
        for (var activity in recentActivities) {
          activityMap[activity.id] = activity;
        }

        // Add or update with Firestore activities
        for (var activity in firestoreActivities) {
          activityMap[activity.id] = activity;
        }

        // Convert back to list and sort
        final List<UserActivity> mergedActivities = activityMap.values.toList();
        mergedActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Update observable list
        recentActivities.assignAll(mergedActivities);

        // Trim if necessary
        if (recentActivities.length > maxStoredActivities) {
          recentActivities.removeRange(
              maxStoredActivities, recentActivities.length);
        }

        // Save to local storage
        await saveActivities();
      }
    } catch (e) {
      print('Error syncing activities from Firestore: $e');
    }
  }

  // Clear all activities
  Future<void> clearActivities() async {
    recentActivities.clear();
    await saveActivities();
  }
}
