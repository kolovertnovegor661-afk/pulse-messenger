import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [Tab(text: 'Users'), Tab(text: 'Promos'), Tab(text: 'Stats')],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        _Users(), _Promos(), _Stats(),
      ]),
    );
  }
}

class _Users extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users')
          .orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
        return ListView.builder(
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, i) {
            final doc = snap.data!.docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(backgroundColor: AppColors.surfaceElevated,
                child: Text((data['displayName'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.textPrimary))),
              title: Row(children: [
                Text(data['displayName'] ?? '', style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                if (data['isVerified'] == true) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified_rounded, color: AppColors.blue, size: 14),
                ],
                if (data['isAdmin'] == true) ...[
                  const SizedBox(width: 4),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(4)),
                    child: const Text('ADMIN', style: TextStyle(color: AppColors.primary,
                        fontSize: 9, fontWeight: FontWeight.w700))),
                ],
              ]),
              subtitle: Text('@${data['username'] ?? ''} • ${(data['swiftTokenBalance'] ?? 0).toInt()} ST',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              trailing: PopupMenuButton<String>(
                color: AppColors.surfaceElevated,
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textTertiary),
                onSelected: (action) async {
                  if (action == 'verify') {
                    await FirebaseFirestore.instance.collection('users').doc(doc.id)
                        .update({'isVerified': true});
                  } else if (action == 'unverify') {
                    await FirebaseFirestore.instance.collection('users').doc(doc.id)
                        .update({'isVerified': false});
                  } else if (action == 'admin') {
                    await FirebaseFirestore.instance.collection('users').doc(doc.id)
                        .update({'isAdmin': true});
                  } else if (action == 'tokens') {
                    final ctrl = TextEditingController();
                    showDialog(context: context, builder: (ctx) => AlertDialog(
                      title: const Text('Add Tokens'),
                      content: TextField(controller: ctrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(hintText: 'Amount')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel')),
                        ElevatedButton(onPressed: () async {
                          final amt = double.tryParse(ctrl.text) ?? 0;
                          if (amt > 0) {
                            await FirebaseFirestore.instance.collection('users').doc(doc.id)
                                .update({'swiftTokenBalance': FieldValue.increment(amt)});
                          }
                          Navigator.pop(ctx);
                        }, child: const Text('Add')),
                      ],
                    ));
                  }
                },
                itemBuilder: (_) => [
                  if (data['isVerified'] != true)
                    const PopupMenuItem(value: 'verify',
                        child: Text('✅ Verify', style: TextStyle(color: AppColors.textPrimary))),
                  if (data['isVerified'] == true)
                    const PopupMenuItem(value: 'unverify',
                        child: Text('Remove Verify', style: TextStyle(color: AppColors.textPrimary))),
                  if (data['isAdmin'] != true)
                    const PopupMenuItem(value: 'admin',
                        child: Text('👑 Make Admin', style: TextStyle(color: AppColors.primary))),
                  const PopupMenuItem(value: 'tokens',
                      child: Text('💰 Add Tokens', style: TextStyle(color: AppColors.swiftGold))),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Promos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _create(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('promoCodes').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
          if (snap.data!.docs.isEmpty) return const Center(
            child: Text('No promo codes\nTap + to create', textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textTertiary)));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, i) {
              final data = snap.data!.docs[i].data() as Map<String, dynamic>;
              final active = data['isActive'] ?? true;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: active
                        ? AppColors.primary.withOpacity(0.3) : AppColors.border)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(data['code'] ?? '', style: const TextStyle(color: AppColors.textPrimary,
                        fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    Text('+${(data['reward'] ?? 0).toInt()} ST • ${data['usedCount'] ?? 0}/${data['maxUses'] ?? 1} uses',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: active ? AppColors.greenSoft : AppColors.surface,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(active ? 'Active' : 'Expired',
                        style: TextStyle(color: active ? AppColors.green : AppColors.textTertiary,
                            fontSize: 12, fontWeight: FontWeight.w600))),
                  IconButton(icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.red, size: 20),
                      onPressed: () => snap.data!.docs[i].reference.delete()),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  void _create(BuildContext context) {
    final codeCtrl = TextEditingController();
    final rewCtrl = TextEditingController();
    final usesCtrl = TextEditingController(text: '1');
    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Create Promo Code', style: TextStyle(color: AppColors.textPrimary,
              fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: codeCtrl, textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Code (e.g. PULSE2024)')),
          const SizedBox(height: 10),
          TextField(controller: rewCtrl, keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Reward in ST')),
          const SizedBox(height: 10),
          TextField(controller: usesCtrl, keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Max uses')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (codeCtrl.text.isEmpty || rewCtrl.text.isEmpty) return;
              await FirebaseFirestore.instance.collection('promoCodes').add({
                'code': codeCtrl.text.trim().toUpperCase(),
                'reward': double.tryParse(rewCtrl.text) ?? 0,
                'maxUses': int.tryParse(usesCtrl.text) ?? 1,
                'usedCount': 0, 'isActive': true,
                'createdAt': FieldValue.serverTimestamp(),
                'createdBy': FirebaseAuth.instance.currentUser?.uid,
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

class _Stats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        _S('Total Users', FirebaseFirestore.instance.collection('users').snapshots(),
            Icons.people_outline_rounded, AppColors.blue),
        const SizedBox(height: 12),
        _S('Total Chats', FirebaseFirestore.instance.collection('chats').snapshots(),
            Icons.chat_bubble_outline_rounded, AppColors.primary),
        const SizedBox(height: 12),
        _S('Total Channels', FirebaseFirestore.instance.collection('channels').snapshots(),
            Icons.campaign_outlined, AppColors.purple),
        const SizedBox(height: 12),
        _S('Gift Transactions', FirebaseFirestore.instance.collection('giftTransactions').snapshots(),
            Icons.redeem_outlined, AppColors.swiftGold),
      ]),
    );
  }

  Widget _S(String label, Stream<QuerySnapshot> stream, IconData icon, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Container(width: 48, height: 48,
                decoration: BoxDecoration(color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(count.toString(), style: TextStyle(color: color, fontSize: 28,
                  fontWeight: FontWeight.w800)),
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ]),
          ]),
        );
      },
    );
  }
}
