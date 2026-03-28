import 'package:cloud_firestore/cloud_firestore.dart';

class GiftModel {
  final String id;
  final String name;
  final String emoji;
  final double price;
  final bool isPremium;

  const GiftModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    this.isPremium = false,
  });

  factory GiftModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GiftModel(
      id: doc.id,
      name: data['name'] ?? '',
      emoji: data['emoji'] ?? '🎁',
      price: (data['price'] ?? 0).toDouble(),
      isPremium: data['isPremium'] ?? false,
    );
  }
}

class ChannelModel {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String ownerId;
  final String ownerName;
  final int subscriberCount;
  final bool isVerified;
  final DateTime createdAt;
  final String? lastPostPreview;

  const ChannelModel({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.ownerId,
    required this.ownerName,
    this.subscriberCount = 0,
    this.isVerified = false,
    required this.createdAt,
    this.lastPostPreview,
  });

  factory ChannelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChannelModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      avatarUrl: data['avatarUrl'],
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      subscriberCount: data['subscriberCount'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastPostPreview: data['lastPostPreview'],
    );
  }
}

class PromoCodeModel {
  final String id;
  final String code;
  final double reward;
  final int maxUses;
  final int usedCount;
  final bool isActive;

  const PromoCodeModel({
    required this.id,
    required this.code,
    required this.reward,
    required this.maxUses,
    this.usedCount = 0,
    this.isActive = true,
  });

  factory PromoCodeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromoCodeModel(
      id: doc.id,
      code: data['code'] ?? '',
      reward: (data['reward'] ?? 0).toDouble(),
      maxUses: data['maxUses'] ?? 1,
      usedCount: data['usedCount'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }
}
