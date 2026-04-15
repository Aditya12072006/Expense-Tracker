import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'providers/subscription_provider.dart';

class CheckoutWebViewScreen extends ConsumerStatefulWidget {
  const CheckoutWebViewScreen({super.key});

  @override
  ConsumerState<CheckoutWebViewScreen> createState() =>
      _CheckoutWebViewScreenState();
}

class _CheckoutWebViewScreenState extends ConsumerState<CheckoutWebViewScreen> {
  late final Razorpay _razorpay;
  bool _didComplete = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCheckout();
    });
  }

  void _openCheckout() {
    if (_didComplete) {
      return;
    }

    final options = {
      'key': razorpayKeyId,
      'amount': premiumAmountPaise,
      'name': 'Expense Tracker Premium',
      'description': 'Unlock full history for 30 days',
      'timeout': 300,
      'theme': {'color': '#3B82F6'},
      'prefill': {
        'contact': '',
        'email': '',
      },
    };

    try {
      _razorpay.open(options);
    } catch (_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    if (_didComplete) {
      return;
    }
    _didComplete = true;

    await ref.read(subscriptionServiceProvider).activatePro();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (_didComplete) {
      return;
    }
    _didComplete = true;
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(false);
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (_didComplete) {
      return;
    }
    _didComplete = true;
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(false);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }

        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Razorpay Checkout'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop(false);
              }
            },
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
