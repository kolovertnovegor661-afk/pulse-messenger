import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserDataProvider).value;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Wallet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.swiftGold.withOpacity(0.2), AppColors.swiftGold.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.swiftGold.withOpacity(0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('SwiftToken Balance',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(user?.swiftTokenBalance.toStringAsFixed(1) ?? '0',
                    style: const TextStyle(color: AppColors.swiftGold, fontSize: 48,
                        fontWeight: FontWeight.w800, letterSpacing: -1)),
                const Padding(padding: EdgeInsets.only(bottom: 10, left: 8),
                    child: Text('ST', style: TextStyle(color: AppColors.swiftGold,
                        fontSize: 20, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                _Btn(icon: Icons.add_rounded, label: 'Top Up',
                    onTap: () => _topUp(context, uid)),
                const SizedBox(width: 12),
                _Btn(icon: Icons.send_rounded, label: 'Send',
                    onTap: () => _sendTokens(context, uid, user?.swiftTokenBalance ?? 0)),
                const SizedBox(width: 12),
                _Btn(icon: Icons.redeem_rounded, label: 'Gift',
                    onTap: () => context.go('/gifts')),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => context.push('/promo'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.local_offer_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Promo Code', style: TextStyle(color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600, fontSize: 15)),
                  Text('Enter a code to get free tokens',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ])),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Transactions', style: TextStyle(color: AppColors.textPrimary,
              fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('giftTransactions')
                .where(Filter.or(Filter('fromUid', isEqualTo: uid),
                    Filter('toUid', isEqualTo: uid)))
                .orderBy('timestamp', descending: true).limit(20).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary));
              if (snap.data!.docs.isEmpty) return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No transactions yet',
                    style: TextStyle(color: AppColors.textTertiary))),
              );
              return Column(children: snap.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final sent = data['fromUid'] == uid;
                final ts = (data['timestamp'] as Timestamp?)?.toDate();
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    Text(data['giftEmoji'] ?? '💸', style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(sent ? 'Sent to ${data['toName']}' : 'From ${data['fromName']}',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                      if (ts != null) Text(ts.toString().substring(0, 16),
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                    ])),
                    Text('${sent ? '-' : '+'}${(data['amount'] ?? 0).toInt()} ST',
                        style: TextStyle(color: sent ? AppColors.red : AppColors.green,
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ]),
                );
              }).toList());
            },
          ),
        ]),
      ),
    );
  }

  void _topUp(BuildContext context, String uid) {
    showModalBottomSheet(context: context, builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Top Up Balance', style: TextStyle(color: AppColors.textPrimary,
            fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Demo mode — select amount to add',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 20),
        Wrap(spacing: 10, runSpacing: 10, children: [50, 100, 250, 500, 1000].map((amt) =>
          GestureDetector(
            onTap: () async {
              await FirebaseFirestore.instance.collection('users').doc(uid)
                  .update({'swiftTokenBalance': FieldValue.increment(amt.toDouble())});
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('+$amt ST added!'),
                backgroundColor: AppColors.green,
              ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: AppColors.swiftGoldSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.swiftGold.withOpacity(0.3))),
              child: Text('$amt ST', style: const TextStyle(
                  color: AppColors.swiftGold, fontWeight: FontWeight.w600)),
            ),
          )).toList()),
        const SizedBox(height: 16),
      ]),
    ));
  }

  void _sendTokens(BuildContext context, String uid, double balance) {
    final userCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Send Tokens', style: TextStyle(color: AppColors.textPrimary,
              fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: userCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Username')),
          const SizedBox(height: 10),
          TextField(controller: amtCtrl, keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Amount (ST)')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text) ?? 0;
              if (amt <= 0 || amt > balance) return;
              final snap = await FirebaseFirestore.instance.collection('users')
                  .where('username', isEqualTo: userCtrl.text.toLowerCase()).limit(1).get();
              if (snap.docs.isEmpty) return;
              final toUid = snap.docs.first.id;
              final batch = FirebaseFirestore.instance.batch();
              batch.update(FirebaseFirestore.instance.collection('users').doc(uid),
                  {'swiftTokenBalance': FieldValue.increment(-amt)});
              batch.update(FirebaseFirestore.instance.collection('users').doc(toUid),
                  {'swiftTokenBalance': FieldValue.increment(amt)});
              await batch.commit();
              Navigator.pop(ctx);
            },
            child: const Text('Send'),
          )),
        ]),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Container(width: 44, height: 44,
          decoration: BoxDecoration(color: AppColors.swiftGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.swiftGold, size: 22)),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    ]),
  );
}
