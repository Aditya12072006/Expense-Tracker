import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'providers/subscription_provider.dart';

class CheckoutWebViewScreen extends ConsumerStatefulWidget {
  const CheckoutWebViewScreen({
    super.key,
    required this.checkoutUri,
  });

  final Uri checkoutUri;

  @override
  ConsumerState<CheckoutWebViewScreen> createState() =>
      _CheckoutWebViewScreenState();
}

class _CheckoutWebViewScreenState extends ConsumerState<CheckoutWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _didComplete = false;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (_) {
                if (!mounted) {
                  return;
                }
                setState(() => _isLoading = true);
              },
              onPageFinished: (_) {
                if (!mounted) {
                  return;
                }
                setState(() => _isLoading = false);
              },
              onNavigationRequest: (request) {
                _handleNavigation(request.url);
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(widget.checkoutUri);
  }

  Future<void> _handleNavigation(String rawUrl) async {
    if (_didComplete) {
      return;
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return;
    }

    final service = ref.read(subscriptionServiceProvider);

    if (service.isCancelledLink(uri) || service.isHostedCheckoutCancelledLink(uri)) {
      _didComplete = true;
      await service.clearPendingCheckout();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(false);
      return;
    }

    if (service.isPaidSuccessLink(uri) || service.isHostedCheckoutSuccessLink(uri)) {
      _didComplete = true;
      await service.activatePro();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    }
  }

  Future<bool> _resolveFromCurrentUrlBeforeExit() async {
    if (_didComplete) {
      return true;
    }

    final currentRawUrl = await _controller.currentUrl();
    final currentUri = currentRawUrl == null ? null : Uri.tryParse(currentRawUrl);
    if (currentUri != null) {
      final service = ref.read(subscriptionServiceProvider);
      if (service.isPaidSuccessLink(currentUri) ||
          service.isHostedCheckoutSuccessLink(currentUri)) {
        _didComplete = true;
        await service.activatePro();
        if (!mounted) {
          return true;
        }
        Navigator.of(context).pop(true);
        return true;
      }

      if (service.isCancelledLink(currentUri) ||
          service.isHostedCheckoutCancelledLink(currentUri)) {
        _didComplete = true;
        await service.clearPendingCheckout();
        if (!mounted) {
          return true;
        }
        Navigator.of(context).pop(false);
        return true;
      }
    }

    await ref.read(subscriptionServiceProvider).clearPendingCheckout();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }

        final navigator = Navigator.of(context);
        final wasHandled = await _resolveFromCurrentUrlBeforeExit();
        if (!wasHandled && navigator.mounted) {
          navigator.pop(false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Secure Checkout'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final wasHandled = await _resolveFromCurrentUrlBeforeExit();
              if (!wasHandled && navigator.mounted) {
                navigator.pop(false);
              }
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const LinearProgressIndicator(minHeight: 2),
          ],
        ),
      ),
    );
  }
}
