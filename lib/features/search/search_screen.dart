import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: TextField(
        controller: _ctrl, autofocus: true,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        decoration: const InputDecoration(
          hintText: 'Search users, channels...',
          hintStyle: TextStyle(color: AppColors.textTertiary),
          border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
        ),
        onChanged: (v) => setState(() => _q = v.toLowerCase()),
      )),
      body: _q.isEmpty
          ? const Center(child: Text('Start typing...',
              style: TextStyle(color: AppColors.textTertiary)))
          : ListView(children: [
              _section('Users', _users()),
              _section('Channels', _channels()),
            ]),
    );
  }

  Widget _section(String title, Widget content) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(title, style: const TextStyle(color: AppColors.textSecondary,
            fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5))),
      content,
      Container(height: 0.5, color: AppColors.border),
    ],
  );

  Widget _users() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users')
          .where('username', isGreaterThanOrEqualTo: _q)
          .where('username', isLessThan: '${_q}z').limit(5).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final users = snap.data!.docs.where((d) => d.id != uid).toList();
        if (users.isEmpty) return const Padding(padding: EdgeInsets.all(16),
            child: Text('No users found', style: TextStyle(color: AppColors.textTertiary)));
        return Column(children: users.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return ListTile(
            leading: CircleAvatar(backgroundColor: AppColors.surfaceElevated,
              backgroundImage: data['avatarUrl'] != null
                  ? CachedNetworkImageProvider(data['avatarUrl']) : null,
              child: data['avatarUrl'] == null
                  ? Text((data['displayName'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: AppColors.textPrimary)) : null),
            title: Text(data['displayName'] ?? '',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            subtitle: Text('@${data['username'] ?? ''}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            onTap: () async {
              final chatId = ([uid, doc.id]..sort()).join('_');
              final ref = FirebaseFirestore.instance.collection('chats').doc(chatId);
              if (!(await ref.get()).exists) {
                final myDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                final myData = myDoc.data() as Map<String, dynamic>;
                await ref.set({
                  'members': [uid, doc.id],
                  'memberNames': {uid: myData['displayName'] ?? '', doc.id: data['displayName'] ?? ''},
                  'memberAvatars': {uid: myData['avatarUrl'], doc.id: data['avatarUrl']},
                  'lastMessageTime': FieldValue.serverTimestamp(),
                  'unreadCount': {uid: 0, doc.id: 0},
                  'isGroup': false,
                });
              }
              if (context.mounted) context.push(
                  '/chat/$chatId?recipientId=${doc.id}&name=${data['displayName']}&avatar=${data['avatarUrl'] ?? ''}');
            },
          );
        }).toList());
      },
    );
  }

  Widget _channels() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('channels')
          .where('name', isGreaterThanOrEqualTo: _q)
          .where('name', isLessThan: '${_q}z').limit(5).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        if (snap.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(16),
            child: Text('No channels found', style: TextStyle(color: AppColors.textTertiary)));
        return Column(children: snap.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return ListTile(
            leading: CircleAvatar(backgroundColor: AppColors.surfaceElevated,
              child: Text((data['name'] ?? 'C')[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.textPrimary))),
            title: Text(data['name'] ?? '',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            subtitle: Text('${data['subscriberCount'] ?? 0} subscribers',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            onTap: () => context.push('/channel/${doc.id}'),
          );
        }).toList());
      },
    );
  }
}
