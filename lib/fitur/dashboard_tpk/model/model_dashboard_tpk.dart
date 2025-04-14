import 'package:flutter/material.dart';

// activity_model.dart
class UserProfileModel {
  final String name;
  final String role;
  final String photoUrl;

  UserProfileModel({
    required this.name,
    required this.role,
    required this.photoUrl,
  });
}

class ActivityModel {
  final IconData icon;
  final String title;
  final String time;
  final bool highlight;

  ActivityModel({
    required this.icon,
    required this.title,
    required this.time,
    this.highlight = false,
  });
}

// inventory_model.dart
class InventoryModel {
  final String woodType;
  final int quantity;
  final String lastUpdated;

  InventoryModel({
    required this.woodType,
    required this.quantity,
    required this.lastUpdated,
  });
}
