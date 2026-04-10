import 'dart:async';

import 'package:app_links/app_links.dart';
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

class _ExpenseTrackerAppState extends ConsumerState<ExpenseTrackerApp>
    with WidgetsBindingObserver {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _deepLinkSubscription;
  String? _lastHandledLink;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLatestDeepLink();
    }
  }

  Future<void> _listenForDeepLinks() async {
    final initial = await _appLinks.getInitialLink();
    if (!mounted) {
      return;
    }
    await _handleDeepLink(initial);

    _deepLinkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      await _handleDeepLink(uri);
    });
  }

  Future<void> _checkLatestDeepLink() async {
    final latest = await _appLinks.getInitialLink();
    if (!mounted) {
      return;
    }
    await _handleDeepLink(latest);
  }

  Future<void> _handleDeepLink(Uri? uri) async {
    if (uri == null) {
      return;
    }

    final service = ref.read(subscriptionServiceProvider);
    if (service.isCancelledLink(uri)) {
      await service.clearPendingCheckout();
      return;
    }

    if (!service.isPaidSuccessLink(uri)) {
      return;
    }

    if (_lastHandledLink == uri.toString()) {
      return;
    }
    _lastHandledLink = uri.toString();

    await service.activatePro();
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: const _PremiumActivatedSnack(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(subscriptionProvider);

    return MaterialApp.router(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
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
            'Premium Activated. Unlimited history is now unlocked.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
