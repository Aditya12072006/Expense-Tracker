import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/subscription/providers/subscription_provider.dart';

class ExpenseTrackerApp extends ConsumerStatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  ConsumerState<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends ConsumerState<ExpenseTrackerApp> {
  bool _wasProActive = false;
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final proState = ref.watch(subscriptionProvider);

    proState.whenData((isProActive) {
      if (!_wasProActive && isProActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }

          final messenger = _messengerKey.currentState;
          if (messenger == null) {
            return;
          }
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 4),
              content: _PremiumActivatedSnack(),
            ),
          );
        });
      }
      _wasProActive = isProActive;
    });

    return MaterialApp.router(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      scaffoldMessengerKey: _messengerKey,
      routerConfig: appRouter,
    );
  }
}

class _PremiumActivatedSnack extends StatelessWidget {
  const _PremiumActivatedSnack();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.celebration_rounded, color: const Color(0xFFF59E0B))
            .animate(onPlay: (controller) => controller.repeat(count: 2))
            .scaleXY(begin: 0.7, end: 1, duration: 450.ms)
            .then()
            .shake(hz: 3),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Premium activated for 30 days. Full history is now unlocked.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
