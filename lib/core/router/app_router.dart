import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/add_transaction/add_transaction_screen.dart';
import '../../features/settings/app_info_screen.dart';
import '../../features/settings/privacy_policy_screen.dart';
import '../../features/root/root_shell.dart';
import '../../features/settings/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const RootShell()),
    GoRoute(
      path: '/add',
      pageBuilder: (context, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          child: const AddTransactionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/app-info',
      builder: (context, state) => const AppInfoScreen(),
    ),
  ],
);
