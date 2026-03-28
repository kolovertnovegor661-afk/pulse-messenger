import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_theme.dart';
import '../../core/models/message_model.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded),
              onPressed: () => context.push('/search')),
          IconButton(icon: const Icon(Icons.edit_rounded),
              onPressed: () => _showNewChat(context)),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('members', arrayContains: uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
          if (snap.data!.docs.isEmpty) return _empty(context);
          final chats = snap.data!.docs.map((d) => ChatModel.fromFirestore(d)).toList();
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, i) => _ChatTile(chat: chats[i], uid: uid),
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: AppColors.surface,
              borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.chat_bubble_outline_rounded,
              color: AppColors.textTertiary, size: 36),
        ),
        const SizedBox(height: 20),
        const Text('No chats yet', style: TextStyle(color: AppColors.textPrimary,
            fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _showNewChat(context),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('New Chat'),
        ),
      ],
    ));
  }

  void _showNewChat(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24, right: 24, top: 24,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('New Chat', style: TextStyle(color: AppColors.textPrimary,
                fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search by username...',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textTertiary),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (ctrl.text.isNotEmpty)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('username', isGreaterThanOrEqualTo: ctrl.text.toLowerCase())
                    .where('username', isLessThan: '${ctrl.text.toLowerCase()}z')
                    .limit(5).snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  final users = snap.data!.docs.where((d) => d.id != uid).toList();
                  return Column(
                    children: users.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.surfaceElevated,
                          backgroundImage: data['avatarUrl'] != null
                              ? CachedNetworkImageProvider(data['avatarUrl']) : null,
                          child: data['avatarUrl'] == null
                              ? Text((data['displayName'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(color: AppColors.textPrimary)) : null,
                        ),
                        title: Text(data['displayName'] ?? '',
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                        subtitle: Text('@${data['username'] ?? ''}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _startChat(context, doc.id, data);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  Future<void> _startChat(BuildContext context, String otherUid,
      Map<String, dynamic> otherData) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final myDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final myData = myDoc.data() as Map<String, dynamic>;
    final chatId = ([uid, otherUid]..sort()).join('_');
    final ref = FirebaseFirestore.instance.collection('chats').doc(chatId);
    if (!(await ref.get()).exists) {
      await ref.set({
        'members': [uid, otherUid],
        'memberNames': {uid: myData['displayName'] ?? '', otherUid: otherData['displayName'] ?? ''},
        'memberAvatars': {uid: myData['avatarUrl'], otherUid: otherData['avatarUrl']},
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {uid: 0, otherUid: 0},
        'isGroup': false,
      });
    }
    if (context.mounted) {
      context.push('/chat/$chatId?recipientId=$otherUid&name=${otherData['displayName']}&avatar=${otherData['avatarUrl'] ?? ''}');
    }
  }
}

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String uid;
  const _ChatTile({required this.chat, required this.uid});

  @override
  Widget build(BuildContext context) {
    final otherUid = chat.members.firstWhere((m) => m != uid, orElse: () => uid);
    final name = chat.memberNames[otherUid] ?? 'Unknown';
    final avatar = chat.memberAvatars[otherUid];
    final unread = chat.unreadCount[uid] ?? 0;

    return ListTile(
      onTap: () => context.push(
          '/chat/${chat.id}?recipientId=$otherUid&name=$name&avatar=${avatar ?? ''}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.surfaceElevated,
        backgroundImage: avatar != null ? CachedNetworkImageProvider(avatar) : null,
        child: avatar == null ? Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(color: AppColors.textPrimary,
              fontSize: 18, fontWeight: FontWeight.w600),
        ) : null,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(name, style: TextStyle(
            color: AppColors.textPrimary, fontSize: 16,
            fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
          ), overflow: TextOverflow.ellipsis)),
          if (chat.lastMessageTime != null)
            Text(timeago.format(chat.lastMessageTime!, locale: 'en_short'),
                style: TextStyle(
                  color: unread > 0 ? AppColors.primary : AppColors.textTertiary,
                  fontSize: 12,
                )),
        ],
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(
            chat.lastMessage ?? 'Start a conversation',
            style: TextStyle(
              color: unread > 0 ? AppColors.textSecondary : AppColors.textTertiary,
              fontSize: 14,
              fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          )),
          if (unread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
              child: Text(unread.toString(),
                  style: const TextStyle(color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}
