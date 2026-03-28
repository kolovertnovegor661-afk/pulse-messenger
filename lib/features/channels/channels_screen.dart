import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/other_models.dart';

class ChannelsScreen extends StatelessWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Channels'),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded),
              onPressed: () => _create(context, uid)),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('channels')
            .orderBy('subscriberCount', descending: true).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
          final channels = snap.data!.docs.map((d) => ChannelModel.fromFirestore(d)).toList();
          if (channels.isEmpty) return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 80, height: 80,
                decoration: BoxDecoration(color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.campaign_outlined,
                    color: AppColors.textTertiary, size: 36)),
              const SizedBox(height: 20),
              const Text('No channels yet', style: TextStyle(color: AppColors.textPrimary,
                  fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _create(context, uid),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Channel'),
              ),
            ],
          ));
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: channels.length,
            itemBuilder: (context, i) => _Tile(channel: channels[i], uid: uid),
          );
        },
      ),
    );
  }

  void _create(BuildContext context, String uid) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Create Channel', style: TextStyle(color: AppColors.textPrimary,
              fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          TextField(controller: nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Channel name')),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Description (optional)')),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final doc = await FirebaseFirestore.instance
                  .collection('users').doc(uid).get();
              final data = doc.data() as Map<String, dynamic>;
              await FirebaseFirestore.instance.collection('channels').add({
                'name': nameCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'ownerId': uid,
                'ownerName': data['displayName'] ?? '',
                'adminIds': [uid],
                'subscriberCount': 0,
                'isVerified': false,
                'isPublic': true,
                'category': 'general',
                'createdAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          )),
        ]),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final ChannelModel channel;
  final String uid;
  const _Tile({required this.channel, required this.uid});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.push('/channel/${channel.id}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 28, backgroundColor: AppColors.surfaceElevated,
        backgroundImage: channel.avatarUrl != null
            ? CachedNetworkImageProvider(channel.avatarUrl!) : null,
        child: channel.avatarUrl == null
            ? Text(channel.name[0].toUpperCase(), style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)) : null,
      ),
      title: Row(children: [
        Expanded(child: Text(channel.name, style: const TextStyle(color: AppColors.textPrimary,
            fontSize: 16, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        if (channel.isVerified)
          const Padding(padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.verified_rounded, color: AppColors.blue, size: 16)),
      ]),
      subtitle: Text('${channel.subscriberCount} subscribers',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      trailing: _SubBtn(channelId: channel.id, uid: uid),
    );
  }
}

class _SubBtn extends StatelessWidget {
  final String channelId, uid;
  const _SubBtn({required this.channelId, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('channels')
          .doc(channelId).collection('subscribers').doc(uid).snapshots(),
      builder: (context, snap) {
        final subbed = snap.data?.exists ?? false;
        return GestureDetector(
          onTap: () async {
            final ref = FirebaseFirestore.instance.collection('channels').doc(channelId);
            if (subbed) {
              await ref.collection('subscribers').doc(uid).delete();
              await ref.update({'subscriberCount': FieldValue.increment(-1)});
            } else {
              await ref.collection('subscribers').doc(uid)
                  .set({'joinedAt': FieldValue.serverTimestamp()});
              await ref.update({'subscriberCount': FieldValue.increment(1)});
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: subbed ? AppColors.surface : AppColors.primary,
              borderRadius: BorderRadius.circular(10),
              border: subbed ? Border.all(color: AppColors.border) : null,
            ),
            child: Text(subbed ? 'Subscribed' : 'Subscribe',
                style: TextStyle(
                  color: subbed ? AppColors.textSecondary : Colors.white,
                  fontSize: 13, fontWeight: FontWeight.w600,
                )),
          ),
        );
      },
    );
  }
}
