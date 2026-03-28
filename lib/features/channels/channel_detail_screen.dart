import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_theme.dart';
import '../../core/models/other_models.dart';

class ChannelDetailScreen extends StatelessWidget {
  final String channelId;
  const ChannelDetailScreen({super.key, required this.channelId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('channels').doc(channelId).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
          final ch = ChannelModel.fromFirestore(snap.data!);
          return CustomScrollView(slivers: [
            SliverAppBar(
              backgroundColor: AppColors.background,
              expandedHeight: 140, pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(ch.name, style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
                background: Container(decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [AppColors.primary.withOpacity(0.3), AppColors.background],
                  ),
                )),
              ),
            ),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(
                    radius: 36, backgroundColor: AppColors.surfaceElevated,
                    backgroundImage: ch.avatarUrl != null
                        ? CachedNetworkImageProvider(ch.avatarUrl!) : null,
                    child: ch.avatarUrl == null
                        ? Text(ch.name[0].toUpperCase(), style: const TextStyle(
                            fontSize: 24, color: AppColors.textPrimary, fontWeight: FontWeight.w700)) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(ch.name, style: const TextStyle(color: AppColors.textPrimary,
                          fontSize: 20, fontWeight: FontWeight.w700)),
                      if (ch.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: AppColors.blue, size: 18),
                      ],
                    ]),
                    Text('${ch.subscriberCount} subscribers',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ])),
                ]),
                if (ch.description != null && ch.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(ch.description!, style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 15)),
                ],
                if (ch.ownerId == uid) ...[
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(
                    onPressed: () => _post(context, ch, uid),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Post'),
                  )),
                ],
              ]),
            )),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('channels')
                  .doc(channelId).collection('posts')
                  .orderBy('createdAt', descending: true).snapshots(),
              builder: (context, pSnap) {
                if (!pSnap.hasData) return const SliverToBoxAdapter(child: SizedBox.shrink());
                if (pSnap.data!.docs.isEmpty) return const SliverToBoxAdapter(
                  child: Padding(padding: EdgeInsets.all(40),
                    child: Center(child: Text('No posts yet',
                        style: TextStyle(color: AppColors.textTertiary)))),
                );
                return SliverList(delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final data = pSnap.data!.docs[i].data() as Map<String, dynamic>;
                    final ts = (data['createdAt'] as Timestamp?)?.toDate();
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(data['text'] ?? '', style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 15)),
                        if (data['mediaUrl'] != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(imageUrl: data['mediaUrl'],
                                width: double.infinity, fit: BoxFit.cover)),
                        ],
                        const SizedBox(height: 8),
                        Text(ts != null ? timeago.format(ts) : '',
                            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                      ]),
                    );
                  },
                  childCount: pSnap.data!.docs.length,
                ));
              },
            ),
          ]);
        },
      ),
    );
  }

  void _post(BuildContext context, ChannelModel ch, String uid) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('New Post', style: TextStyle(color: AppColors.textPrimary,
              fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: ctrl, maxLines: 6,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Write something...')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) return;
              await FirebaseFirestore.instance.collection('channels')
                  .doc(ch.id).collection('posts').add({
                'text': ctrl.text.trim(),
                'authorId': uid,
                'authorName': ch.ownerName,
                'createdAt': FieldValue.serverTimestamp(),
              });
              await FirebaseFirestore.instance.collection('channels').doc(ch.id).update({
                'lastPostPreview': ctrl.text.trim(),
                'lastPostTime': FieldValue.serverTimestamp(),
              });
              Navigator.pop(ctx);
            },
            child: const Text('Publish'),
          )),
        ]),
      ),
    );
  }
}
