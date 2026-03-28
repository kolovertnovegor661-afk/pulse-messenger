import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';

class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});
  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _msg;
  bool _ok = false;

  Future<void> _apply() async {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() { _loading = true; _msg = null; });
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final used = List<String>.from((userDoc.data() as Map)['usedPromoCodes'] ?? []);
    if (used.contains(code)) {
      setState(() { _loading = false; _ok = false; _msg = 'Already used this code'; });
      return;
    }
    final snap = await FirebaseFirestore.instance.collection('promoCodes')
        .where('code', isEqualTo: code).where('isActive', isEqualTo: true).limit(1).get();
    if (snap.docs.isEmpty) {
      setState(() { _loading = false; _ok = false; _msg = 'Invalid or expired code'; });
      return;
    }
    final promo = snap.docs.first;
    final data = promo.data() as Map<String, dynamic>;
    final reward = (data['reward'] ?? 0).toDouble();
    final maxUses = data['maxUses'] ?? 1;
    final usedCount = data['usedCount'] ?? 0;
    final expires = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expires != null && DateTime.now().isAfter(expires)) {
      setState(() { _loading = false; _ok = false; _msg = 'This code has expired'; });
      return;
    }
    if (usedCount >= maxUses) {
      setState(() { _loading = false; _ok = false; _msg = 'Code fully used up'; });
      return;
    }
    final batch = FirebaseFirestore.instance.batch();
    batch.update(FirebaseFirestore.instance.collection('users').doc(uid), {
      'swiftTokenBalance': FieldValue.increment(reward),
      'usedPromoCodes': FieldValue.arrayUnion([code]),
    });
    batch.update(promo.reference, {
      'usedCount': FieldValue.increment(1),
      if (usedCount + 1 >= maxUses) 'isActive': false,
    });
    await batch.commit();
    setState(() {
      _loading = false; _ok = true;
      _msg = '+${reward.toInt()} ST added to your wallet! 🎉';
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Promo Code')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.2))),
            child: const Column(children: [
              Text('🎟️', style: TextStyle(fontSize: 48)),
              SizedBox(height: 12),
              Text('Enter Promo Code', style: TextStyle(color: AppColors.textPrimary,
                  fontSize: 20, fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text('Get free SwiftTokens', style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
            ]),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18,
                fontWeight: FontWeight.w600, letterSpacing: 2),
            decoration: const InputDecoration(
              hintText: 'PULSE2024',
              prefixIcon: Icon(Icons.confirmation_number_outlined, color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(height: 16),
          if (_msg != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: _ok ? AppColors.greenSoft : AppColors.redSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _ok
                      ? AppColors.green.withOpacity(0.3) : AppColors.red.withOpacity(0.3))),
              child: Row(children: [
                Icon(_ok ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                    color: _ok ? AppColors.green : AppColors.red, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(_msg!, style: TextStyle(
                    color: _ok ? AppColors.green : AppColors.red, fontWeight: FontWeight.w500))),
              ]),
            ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _apply,
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Apply Code'),
            ),
          ),
        ]),
      ),
    );
  }
}
