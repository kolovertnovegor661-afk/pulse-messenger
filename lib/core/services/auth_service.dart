import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserDataProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(currentUserProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await _createUser(result.user!, username: username, displayName: displayName);
    return result;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> _createUser(User user, {String? username, String? displayName}) async {
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _db.collection('users').doc(user.uid).set({
        'username': username ?? 'user_${user.uid.substring(0, 8)}',
        'displayName': displayName ?? 'User',
        'email': user.email ?? '',
        'avatarUrl': null,
        'bio': '',
        'isVerified': false,
        'isAdmin': false,
        'swiftTokenBalance': 100.0,
        'totalGiftsSent': 0,
        'totalGiftsReceived': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': true,
        'usedPromoCodes': [],
      });
    } else {
      await _db.collection('users').doc(user.uid).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> signOut() async {
    await _db.collection('users').doc(_auth.currentUser?.uid).update({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
    await _auth.signOut();
  }

  Future<bool> isUsernameAvailable(String username) async {
    final q = await _db.collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1).get();
    return q.docs.isEmpty;
  }
}
