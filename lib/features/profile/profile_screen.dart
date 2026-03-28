import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserDataProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: userData.when(
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Stack(children: [
                CircleAvatar(
                  radius: 52, backgroundColor: AppColors.surfaceElevated,
                  backgroundImage: user.avatarUrl != null
                      ? CachedNetworkImageProvider(user.avatarUrl!) : null,
                  child: user.avatarUrl == null ? Text(
                    user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.textPrimary,
                        fontSize: 36, fontWeight: FontWeight.w700),
                  ) : null,
                ),
                if (user.isVerified)
                  Positioned(bottom: 0, right: 0,
                    child: Container(width: 28, height: 28,
                      decoration: BoxDecoration(color: AppColors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 2)),
                      child: const Icon(Icons.verified_rounded, color: Colors.white, size: 16)),
                  ),
              ]),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(user.displayName, style: const TextStyle(color: AppColors.textPrimary,
                    fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                if (user.isVerified) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified_rounded, color: AppColors.blue, size: 20),
                ],
                if (user.isAdmin) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('ADMIN', style: TextStyle(color: AppColors.primary,
                        fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
              const SizedBox(height: 4),
              Text('@${user.username}', style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 15)),
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(user.bio!, textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.swiftGoldSoft, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.swiftGold.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Container(width: 48, height: 48,
                    decoration: BoxDecoration(color: AppColors.swiftGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14)),
                    child: const Center(child: Text('ST', style: TextStyle(
                        color: AppColors.swiftGold, fontSize: 16, fontWeight: FontWeight.w800))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('SwiftToken Balance',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text('${user.swiftTokenBalance.toStringAsFixed(1)} ST',
                        style: const TextStyle(color: AppColors.swiftGold, fontSize: 22,
                            fontWeight: FontWeight.w700)),
                  ])),
                  TextButton(
                    onPressed: () => context.go('/wallet'),
                    child: const Text('Wallet',
                        style: TextStyle(color: AppColors.swiftGold, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                _stat('Sent', user.totalGiftsSent.toString(), Icons.send_rounded, AppColors.primary),
                const SizedBox(width: 12),
                _stat('Received', user.totalGiftsReceived.toString(), Icons.redeem_rounded, AppColors.purple),
              ]),
              const SizedBox(height: 24),
              _action(Icons.edit_outlined, 'Edit Profile', () => context.push('/profile/edit')),
              _action(Icons.local_offer_outlined, 'Promo Code', () => context.push('/promo')),
              if (user.isAdmin)
                _action(Icons.admin_panel_settings_outlined, 'Admin Panel',
                    () => context.push('/admin'), color: AppColors.primary),
              const SizedBox(height: 8),
              _action(Icons.logout_rounded, 'Sign Out', () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/auth');
              }, color: AppColors.red),
            ]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const Center(child: Text('Error')),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ]),
      ]),
    ));
  }

  Widget _action(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? AppColors.textPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border)),
      child: ListTile(
        leading: Icon(icon, color: c, size: 20),
        title: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w500, fontSize: 15)),
        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
