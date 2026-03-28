import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final bool isVerified;
  final bool isAdmin;
  final double swiftTokenBalance;
  final int totalGiftsSent;
  final int totalGiftsReceived;
  final DateTime createdAt;
  final bool isOnline;
  final List<String> usedPromoCodes;

  const UserModel({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.isVerified = false,
    this.isAdmin = false,
    this.swiftTokenBalance = 0.0,
    this.totalGiftsSent = 0,
    this.totalGiftsReceived = 0,
    required this.createdAt,
    this.isOnline = false,
    this.usedPromoCodes = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      username: data['username'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'],
      bio: data['bio'],
      isVerified: data['isVerified'] ?? false,
      isAdmin: data['isAdmin'] ?? false,
      swiftTokenBalance: (data['swiftTokenBalance'] ?? 0).toDouble(),
      totalGiftsSent: data['totalGiftsSent'] ?? 0,
      totalGiftsReceived: data['totalGiftsReceived'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOnline: data['isOnline'] ?? false,
      usedPromoCodes: List<String>.from(data['usedPromoCodes'] ?? []),
    );
  }
}
