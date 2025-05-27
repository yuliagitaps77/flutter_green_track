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
      {int limit = 20, DocumentSnapshot? lastDocument}) async {
    try {
      Query query = _activitiesCollection
          .orderBy('timestamp', descending: true)
          .limit(limit);

      // If we have a last document, start after it
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();

      // Filter and map activities on client side
      return snapshot.docs
          .map((doc) {
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
          })
          .where((activity) =>
              activity.userId == userId) // Filter by userId on client
          .toList();
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
  // Global activities
  static const String userLogin = 'USER_LOGIN';
  static const String userLogout = 'USER_LOGOUT';
  static const String updateUserProfile = 'UPDATE_USER_PROFILE';
  static const String changePassword = 'CHANGE_PASSWORD';

  // Admin Penyemaian activities
  static const String scanBarcode = 'SCAN_BARCODE';
  static const String printBarcode = 'PRINT_BARCODE';
  static const String updateBibit = 'UPDATE_BIBIT';
  static const String deleteBibit = 'DELETE_BIBIT';
  static const String addJadwalRawat = 'ADD_JADWAL_RAWAT';

  // Expanded Jadwal Rawat types
  static const String addJadwalPenyiraman = 'ADD_JADWAL_PENYIRAMAN';
  static const String addJadwalPemupukan = 'ADD_JADWAL_PEMUPUKAN';
  static const String addJadwalPengecekan = 'ADD_JADWAL_PENGECEKAN';
  static const String addJadwalPenyiangan = 'ADD_JADWAL_PENYIANGAN';
  static const String addJadwalPenyemprotan = 'ADD_JADWAL_PENYEMPROTAN';
  static const String addJadwalPemangkasan = 'ADD_JADWAL_PEMANGKASAN';
  static const String updateJadwalRawat = 'UPDATE_JADWAL_RAWAT';
  static const String completeJadwalRawat = 'COMPLETE_JADWAL_RAWAT';
  static const String deleteJadwalRawat = 'DELETE_JADWAL_RAWAT';

  // Admin TPK activities
  static const String scanPohon = 'SCAN_POHON';
  static const String addKayu = 'ADD_KAYU';
  static const String updateKayu = 'UPDATE_KAYU';
  static const String deleteKayu = 'DELETE_KAYU';
  static const String addPengiriman = 'ADD_PENGIRIMAN';
}

class AppController extends GetxController {
  static AppController get to => Get.find();

  // Observable list of recent activities
  final recentActivities = <UserActivity>[].obs;

  // Pagination related properties
  final isLoadingMore = false.obs;
  final hasMoreData = true.obs;
  DocumentSnapshot? lastDocument;
  final int pageSize = 10;

  // Cache related properties
  final String cacheKey = 'cached_activities';
  final String lastSyncKey = 'last_sync_timestamp';
  final Duration cacheValidity =
      Duration(minutes: 5); // Cache valid for 5 minutes

  // Maximum number of activities to store locally
  final int maxStoredActivities = 50;

  // Storage key for activities
  final String storageKey = 'user_activities';

  // Current user
  late final Rx<UserModel?> currentUser;

  // Firestore Activity Service
  final FirestoreActivityService _firestoreActivityService =
      FirestoreActivityService();

  // Get Firestore collection reference
  CollectionReference get _activitiesCollection =>
      FirebaseFirestore.instance.collection('activities');

  // Map of description templates by activity type
  final Map<String, String> _activityDescriptions = {
    // Global activities
    ActivityTypes.userLogin: 'User {name} berhasil login',
    ActivityTypes.userLogout: 'User {name} berhasil logout',
    ActivityTypes.updateUserProfile:
        'User {name} Melakukan Update Data Diri berhasil',
    ActivityTypes.changePassword: 'User {name} mengubah password',

    // Admin Penyemaian activities
    ActivityTypes.scanBarcode: 'Scan Barcode Pada Bibit {name}',
    ActivityTypes.printBarcode: 'Mencetak Barcode Untuk Bibit {name}',
    ActivityTypes.updateBibit: 'Mengupdate Bibit {name}',
    ActivityTypes.deleteBibit: 'Menghapus Bibit {name}',

    // Jadwal activities
    ActivityTypes.addJadwalRawat: 'Membuat Jadwal Perawatan Untuk Bibit {name}',
    ActivityTypes.addJadwalPenyiraman:
        'Membuat Jadwal Perawatan Penyiraman Untuk Bibit {name}',
    ActivityTypes.addJadwalPemupukan:
        'Membuat Jadwal Perawatan Pemupukan Untuk Bibit {name}',
    ActivityTypes.addJadwalPengecekan:
        'Membuat Jadwal Perawatan Pengecekan Untuk Bibit {name}',
    ActivityTypes.addJadwalPenyiangan:
        'Membuat Jadwal Perawatan Penyiangan Untuk Bibit {name}',
    ActivityTypes.addJadwalPenyemprotan:
        'Membuat Jadwal Perawatan Penyemprotan Untuk Bibit {name}',
    ActivityTypes.addJadwalPemangkasan:
        'Membuat Jadwal Perawatan Pemangkasan Untuk Bibit {name}',
    ActivityTypes.updateJadwalRawat: 'Mengupdate Jadwal Perawatan Bibit {name}',
    ActivityTypes.completeJadwalRawat:
        'Mengupdate Jadwal Perawatan {name} Menjadi Selesai',
    ActivityTypes.deleteJadwalRawat: 'Menghapus Jadwal Perawatan x {name}',

    // Admin TPK activities
    ActivityTypes.scanPohon: 'Scan Pohon {name}',
    ActivityTypes.addKayu: 'Menambahkan Kayu {name}',
    ActivityTypes.updateKayu: 'Mengupdate Kayu {name}',
    ActivityTypes.deleteKayu: 'Menghapus Kayu {name}',
    ActivityTypes.addPengiriman: 'Menambahkan Pengiriman {name}'
  };

  @override
  void onInit() {
    super.onInit();
    // Get user from auth controller
    final authController = Get.find<AuthenticationController>();
    currentUser = authController.currentUser;

    // Load cached activities first and then sync if needed
    loadCachedActivities().then((_) {
      // If no activities in cache or activities list is empty, sync from Firestore
      if (recentActivities.isEmpty) {
        syncActivitiesFromFirestore(refresh: true);
      }
    });
  }

  // Load cached activities
  Future<void> loadCachedActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);
      final lastSync = prefs.getInt(lastSyncKey);

      if (cachedData != null && lastSync != null) {
        final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
        final now = DateTime.now();

        // Check if cache is still valid
        if (now.difference(lastSyncTime) < cacheValidity) {
          final List<dynamic> decoded = jsonDecode(cachedData);
          final activities =
              decoded.map((item) => UserActivity.fromJson(item)).toList();
          recentActivities.assignAll(activities);
          return;
        }
      }

      // If no cache or cache expired, load from storage
      await loadActivities();
    } catch (e) {
      print('Error loading cached activities: $e');
      await loadActivities();
    }
  }

  // Save activities to cache
  Future<void> saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = jsonEncode(
          recentActivities.map((activity) => activity.toJson()).toList());
      await prefs.setString(cacheKey, activitiesJson);
      await prefs.setInt(lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error saving to cache: $e');
    }
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
    required String activityType, // didapatkan dari enum ActivityTypes
    required String name, // Nama objek (bibit, pohon, kayu) atau user
    String? targetId,
    Map<String, dynamic>? metadata,
  }) async {
    print('🔍 [ACTIVITY] Recording activity: $activityType for $name');

    // Ensure user is logged in
    if (currentUser.value == null) {
      print('⚠️ [ACTIVITY] Cannot record activity: User not logged in');
      return;
    }

    // Generate description from template
    final template = _activityDescriptions[activityType] ?? 'Activity: {name}';
    final description = template.replaceAll('{name}', name);
    print('📝 [ACTIVITY] Description: $description');

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
    print('✅ [ACTIVITY] Created activity record with ID: ${activity.id}');

    // Add to list (at the beginning)
    recentActivities.insert(0, activity);
    print(
        '📊 [ACTIVITY] Added to recent activities (total: ${recentActivities.length})');

    // Trim list if it exceeds maximum
    if (recentActivities.length > maxStoredActivities) {
      print(
          '🔄 [ACTIVITY] Trimming activities list to $maxStoredActivities items');
      recentActivities.removeRange(
          maxStoredActivities, recentActivities.length);
    }

    // Save to local storage
    await saveActivities();
    print('💾 [ACTIVITY] Saved activities to local storage');

    // Save to Firestore jika user sudah login
    if (currentUser.value != null) {
      print(
          '🔥 [ACTIVITY] Saving activity to Firestore for user: ${currentUser.value!.id}');
      await _firestoreActivityService.recordActivityToFirestore(
          activity, currentUser.value!);
      print('✅ [ACTIVITY] Successfully saved to Firestore');
    }

    print('✅ [ACTIVITY] Activity recording completed');
  }

  // Helper method to get icon for activity type
  String? _getIconForActivityType(String activityType) {
    final Map<String, String> activityIcons = {
      // Global activities booth admin penyemaian and admin tpk
      ActivityTypes.userLogin: 'Icons.login_rounded',
      ActivityTypes.userLogout: 'Icons.logout_rounded',
      ActivityTypes.updateUserProfile: 'Icons.person_rounded',
      ActivityTypes.changePassword: 'Icons.password_rounded',

      // Admin Penyemaian activities
      ActivityTypes.scanBarcode: 'Icons.qr_code_scanner_rounded',
      ActivityTypes.printBarcode: 'Icons.print_rounded',
      ActivityTypes.updateBibit: 'Icons.edit',
      ActivityTypes.deleteBibit: 'Icons.delete',
      ActivityTypes.addJadwalRawat: 'Icons.calendar_month_rounded',

      // Admin Penyemaian Activities Jadwal Rawat types
      ActivityTypes.addJadwalPenyiraman: 'Icons.water_drop_rounded',
      ActivityTypes.addJadwalPemupukan: 'Icons.compost_rounded',
      ActivityTypes.addJadwalPengecekan: 'Icons.fact_check_rounded',
      ActivityTypes.addJadwalPenyiangan: 'Icons.grass_rounded',
      ActivityTypes.addJadwalPenyemprotan: 'Icons.sanitizer_rounded',
      ActivityTypes.addJadwalPemangkasan: 'Icons.content_cut_rounded',
      ActivityTypes.updateJadwalRawat: 'Icons.edit_calendar_rounded',
      ActivityTypes.completeJadwalRawat: 'Icons.task_alt_rounded',
      ActivityTypes.deleteJadwalRawat: 'Icons.event_busy_rounded',

      // Admin TPK activities
      ActivityTypes.scanPohon: 'Icons.qr_code_scanner_rounded',
      ActivityTypes.addKayu: 'Icons.add_circle_outline_rounded',
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

  // Sync activities from Firestore with caching
  Future<void> syncActivitiesFromFirestore({bool refresh = false}) async {
    if (currentUser.value == null) return;

    try {
      // Check if we need to refresh based on cache
      if (!refresh) {
        final prefs = await SharedPreferences.getInstance();
        final lastSync = prefs.getInt(lastSyncKey);
        if (lastSync != null) {
          final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
          final now = DateTime.now();
          if (now.difference(lastSyncTime) < cacheValidity) {
            // Cache is still valid, no need to sync
            return;
          }
        }
      }

      // Reset pagination if refreshing
      if (refresh) {
        lastDocument = null;
        hasMoreData.value = true;
        recentActivities.clear();
      }

      if (!hasMoreData.value || isLoadingMore.value) return;

      isLoadingMore.value = true;

      // Get user activities from Firestore with pagination
      final firestoreActivities =
          await _firestoreActivityService.getActivitiesForUserFromFirestore(
        currentUser.value!.id,
        limit: pageSize,
        lastDocument: lastDocument,
      );

      if (firestoreActivities.isNotEmpty) {
        // Update last document for next pagination
        lastDocument =
            await _activitiesCollection.doc(firestoreActivities.last.id).get();

        // Add new activities to the list
        recentActivities.addAll(firestoreActivities);

        // Check if we have more data
        hasMoreData.value = firestoreActivities.length >= pageSize;

        // Trim if necessary
        if (recentActivities.length > maxStoredActivities) {
          recentActivities.removeRange(
              maxStoredActivities, recentActivities.length);
        }

        // Save to cache and local storage
        await Future.wait([
          saveToCache(),
          saveActivities(),
        ]);
      } else {
        hasMoreData.value = false;
      }
    } catch (e) {
      print('Error syncing activities from Firestore: $e');
      hasMoreData.value = false;
    } finally {
      isLoadingMore.value = false;
    }
  }

  // Load more activities when scrolling
  Future<void> loadMoreActivities() async {
    if (!isLoadingMore.value && hasMoreData.value) {
      await syncActivitiesFromFirestore();
    }
  }

  // Refresh activities
  Future<void> refreshActivities() async {
    await syncActivitiesFromFirestore(refresh: true);
  }

  // Clear all activities
  Future<void> clearActivities() async {
    recentActivities.clear();
    await saveActivities();
  }
}
