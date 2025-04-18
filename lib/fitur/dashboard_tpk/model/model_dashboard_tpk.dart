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
