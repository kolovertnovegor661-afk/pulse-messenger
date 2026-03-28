import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/chats/chats_screen.dart';
import '../../features/chats/chat_detail_screen.dart';
import '../../features/channels/channels_screen.dart';
import '../../features/channels/channel_detail_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/gifts/gifts_screen.dart';
import '../../features/wallet/wallet_screen.dart';
import '../../features/admin/admin_screen.dart';
import '../../features/promo/promo_screen.dart';
import '../../features/search/search_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isAuth = user != null;
      final isAuthRoute = state.matchedLocation == '/auth';
      if (!isAuth && !isAuthRoute) return '/auth';
      if (isAuth && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const ChatsScreen()),
          GoRoute(path: '/channels', builder: (_, __) => const ChannelsScreen()),
          GoRoute(path: '/gifts', builder: (_, __) => const GiftsScreen()),
          GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/chat/:chatId',
        builder: (context, state) => ChatDetailScreen(
          chatId: state.pathParameters['chatId']!,
          recipientId: state.uri.queryParameters['recipientId'] ?? '',
          recipientName: state.uri.queryParameters['name'] ?? '',
          recipientAvatar: state.uri.queryParameters['avatar'] ?? '',
        ),
      ),
      GoRoute(
        path: '/channel/:channelId',
        builder: (context, state) =>
            ChannelDetailScreen(channelId: state.pathParameters['channelId']!),
      ),
      GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/promo', builder: (_, __) => const PromoScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
    ],
  );
});
