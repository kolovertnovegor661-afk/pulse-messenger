import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/other_models.dart';
import '../../core/services/auth_service.dart';

class GiftsScreen extends ConsumerStatefulWidget {
  const GiftsScreen({super.key});
  @override
  ConsumerState<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends ConsumerState<GiftsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _seed();
  }

  Future<void> _seed() async {
    final snap = await FirebaseFirestore.instance.collection('gifts').limit(1).get();
    if (snap.docs.isNotEmpty) return;
    for (final g in [
      {'name': 'Heart', 'emoji': '❤️', 'price': 10.0},
      {'name': 'Star', 'emoji': '⭐', 'price': 5.0},
      {'name': 'Fire', 'emoji': '🔥', 'price': 15.0},
      {'name': 'Diamond', 'emoji': '💎', 'price': 50.0, 'isPremium': true},
      {'name': 'Crown', 'emoji': '👑', 'price': 100.0, 'isPremium': true},
      {'name': 'Rose', 'emoji': '🌹', 'price': 20.0},
      {'name': 'Trophy', 'emoji': '🏆', 'price': 30.0},
      {'name': 'Rainbow', 'emoji': '🌈', 'price': 25.0},
      {'name': 'Magic', 'emoji': '✨', 'price': 35.0},
      {'name': 'Gift Box', 'emoji': '🎁', 'price': 8.0},
      {'name': 'Cake', 'emoji': '🎂', 'price': 12.0},
      {'name': 'Fireworks', 'emoji': '🎆', 'price': 18.0},
    ]) {
      await FirebaseFirestore.instance.collection('gifts').add({
        ...g, 'isPremium': g['isPremium'] ?? false, 'sendCount': 0,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gifts'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [Tab(text: 'Send Gift'), Tab(text: 'My Gifts')],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        _SendTab(),
        _ReceivedTab(),
      ]),
    );
  }
}

class _SendTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(currentUserDataProvider).value?.swiftTokenBalance ?? 0;
    return Column(children: [
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.swiftGoldSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.swiftGold.withOpacity(0.3))),
        child: Row(children: [
          const Text('💰', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Your balance', style: TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
            Text('${balance.toStringAsFixed(1)} ST', style: const TextStyle(
                color: AppColors.swiftGold, fontSize: 20, fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('gifts').orderBy('price').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
          final gifts = snap.data!.docs.map((d) => GiftModel.fromFirestore(d)).toList();
          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 12,
              mainAxisSpacing: 12, childAspectRatio: 0.85,
            ),
            itemCount: gifts.length,
            itemBuilder: (context, i) => _GiftCard(gift: gifts[i], balance: balance),
          );
        },
      )),
    ]);
  }
}

class _GiftCard extends StatelessWidget {
  final GiftModel gift;
  final double balance;
  const _GiftCard({required this.gift, required this.balance});

  @override
  Widget build(BuildContext context) {
    final can = balance >= gift.price;
    return GestureDetector(
      onTap: () => _send(context),
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gift.isPremium
                ? AppColors.swiftGold.withOpacity(0.4) : AppColors.border)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(gift.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 6),
          Text(gift.name, style: const TextStyle(color: AppColors.textPrimary,
              fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: can ? AppColors.swiftGoldSoft : AppColors.surface,
                borderRadius: BorderRadius.circular(6)),
            child: Text('${gift.price.toInt()} ST', style: TextStyle(
                color: can ? AppColors.swiftGold : AppColors.textTertiary,
                fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  void _send(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24, right: 24, top: 24,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Send ${gift.emoji} ${gift.name}',
                style: const TextStyle(color: AppColors.textPrimary,
                    fontSize: 20, fontWeight: FontWeight.w700)),
            Text('Cost: ${gift.price.toInt()} ST',
                style: const TextStyle(color: AppColors.swiftGold, fontSize: 14)),
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
                stream: FirebaseFirestore.instance.collection('users')
                    .where('username', isGreaterThanOrEqualTo: ctrl.text.toLowerCase())
                    .where('username', isLessThan: '${ctrl.text.toLowerCase()}z')
                    .limit(5).snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  return Column(
                    children: snap.data!.docs.where((d) => d.id != uid).map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['displayName'] ?? '',
                            style: const TextStyle(color: AppColors.textPrimary)),
                        subtitle: Text('@${data['username'] ?? ''}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        trailing: ElevatedButton(
                          onPressed: balance >= gift.price ? () async {
                            final fromUid = FirebaseAuth.instance.currentUser!.uid;
                            final fromDoc = await FirebaseFirestore.instance
                                .collection('users').doc(fromUid).get();
                            final fromData = fromDoc.data() as Map<String, dynamic>;
                            final batch = FirebaseFirestore.instance.batch();
                            batch.set(FirebaseFirestore.instance.collection('giftTransactions').doc(), {
                              'giftId': gift.id, 'giftName': gift.name, 'giftEmoji': gift.emoji,
                              'fromUid': fromUid, 'fromName': fromData['displayName'] ?? '',
                              'fromAvatar': fromData['avatarUrl'],
                              'toUid': doc.id, 'toName': data['displayName'] ?? '',
                              'toAvatar': data['avatarUrl'],
                              'amount': gift.price,
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                            batch.update(FirebaseFirestore.instance.collection('users').doc(fromUid),
                                {'swiftTokenBalance': FieldValue.increment(-gift.price),
                                  'totalGiftsSent': FieldValue.increment(1)});
                            batch.update(FirebaseFirestore.instance.collection('users').doc(doc.id),
                                {'totalGiftsReceived': FieldValue.increment(1)});
                            await batch.commit();
                            Navigator.pop(ctx);
                          } : null,
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                          child: const Text('Send'),
                        ),
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
}

class _ReceivedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('giftTransactions')
          .where('toUid', isEqualTo: uid)
          .orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
        if (snap.data!.docs.isEmpty) return const Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎁', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text('No gifts received yet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        ));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, i) {
            final data = snap.data!.docs[i].data() as Map<String, dynamic>;
            final ts = (data['timestamp'] as Timestamp?)?.toDate();
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Text(data['giftEmoji'] ?? '🎁', style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(data['giftName'] ?? '', style: const TextStyle(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  Text('From ${data['fromName'] ?? ''}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  if (ts != null) Text(ts.toString().substring(0, 16),
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                ])),
                Text('${(data['amount'] ?? 0).toInt()} ST',
                    style: const TextStyle(color: AppColors.swiftGold,
                        fontWeight: FontWeight.w600)),
              ]),
            );
          },
        );
      },
    );
  }
}
