// lib/models/banner.dart

import 'package:cloud_firestore/cloud_firestore.dart';
class AdBanner {
  final String id;
  final String imageUrl;
  final bool isActive;
  final String title;
  final String subtitle;
  final String actionType; // 'category', 'product', 'none'
  final String target;     // Category name or Product ID

  AdBanner({
    required this.id,
    required this.imageUrl,
    required this.isActive,
    required this.title,
    required this.subtitle,
    required this.actionType,
    required this.target,
  });

  factory AdBanner.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AdBanner(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      isActive: data['isActive'] ?? false,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      actionType: data['actionType'] ?? 'none',
      target: data['target'] ?? '',
    );
  }
}