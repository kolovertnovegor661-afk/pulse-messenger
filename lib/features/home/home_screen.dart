import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';

class HomeScreen extends ConsumerWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/channels')) return 1;
    if (location.startsWith('/gifts')) return 2;
    if (location.startsWith('/wallet')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    final userData = ref.watch(currentUserDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          onTap: (index) {
            switch (index) {
              case 0: context.go('/'); break;
              case 1: context.go('/channels'); break;
              case 2: context.go('/gifts'); break;
              case 3: context.go('/wallet'); break;
              case 4: context.go('/profile'); break;
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Chats',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined),
              activeIcon: Icon(Icons.campaign_rounded),
              label: 'Channels',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.redeem_outlined),
              activeIcon: Icon(Icons.redeem_rounded),
              label: 'Gifts',
            ),
            BottomNavigationBarItem(
              icon: userData.when(
                data: (user) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined),
                    if (user != null)
                      Positioned(
                        top: -4, right: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.swiftGold,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.swiftTokenBalance.toInt().toString(),
                            style: const TextStyle(color: Colors.black,
                                fontSize: 8, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
                loading: () => const Icon(Icons.account_balance_wallet_outlined),
                error: (_, __) => const Icon(Icons.account_balance_wallet_outlined),
              ),
              activeIcon: const Icon(Icons.account_balance_wallet_rounded),
              label: 'Wallet',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
