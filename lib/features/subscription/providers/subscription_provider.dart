import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_boxes.dart';

const String checkoutUrl =
  'https://adityaexpensetracker.lemonsqueezy.com/checkout/buy/d0400634-bae5-4303-8f09-8a58e581e101';
const int variantId = 1506832;

class SubscriptionService {
  SubscriptionService(this._box);

  static const String deepLinkScheme = 'expensetracker';
  static const String deepLinkHost = 'success';
  static const String isProActiveKey = 'is_pro_active';
  static const String purchaseDateKey = 'pro_purchase_date_ms';
  static const String pendingCheckoutNonceKey = 'pro_pending_checkout_nonce';
  static const String pendingCheckoutStartedAtKey =
      'pro_pending_checkout_started_at_ms';
  static const Duration pendingCheckoutMaxAge = Duration(hours: 2);

  final Box<dynamic> _box;

  Stream<BoxEvent> watchChanges() => _box.watch();

  bool isPaidSuccessLink(Uri uri) {
    if (uri.scheme != deepLinkScheme || uri.host != deepLinkHost) {
      return false;
    }

    final status = uri.queryParameters['status'];
    if (status != null && status != 'paid') {
      return false;
    }

    final receivedVariantId = uri.queryParameters['variant_id'];
    if (receivedVariantId != null && receivedVariantId != variantId.toString()) {
      return false;
    }

    final startedAt = pendingCheckoutStartedAt;
    if (startedAt == null) {
      return false;
    }
    final age = DateTime.now().difference(startedAt);
    if (age > pendingCheckoutMaxAge) {
      return false;
    }

    final pendingNonce = _box.get(pendingCheckoutNonceKey);
    if (pendingNonce is! String || pendingNonce.isEmpty) {
      return false;
    }

    final callbackNonce = uri.queryParameters['nonce'];
    if (callbackNonce != null && callbackNonce != pendingNonce) {
      return false;
    }

    return true;
  }

  bool isCancelledLink(Uri uri) {
    if (uri.scheme != deepLinkScheme || uri.host != deepLinkHost) {
      return false;
    }
    return uri.queryParameters['status'] == 'cancelled';
  }

  bool isHostedCheckoutSuccessLink(Uri uri) {
    if (!hasRecentPendingCheckout) {
      return false;
    }

    final host = uri.host.toLowerCase();
    if (!host.endsWith('lemonsqueezy.com')) {
      return false;
    }

    final redirectStatus = uri.queryParameters['redirect_status'];
    final hasPaymentIntent = uri.queryParameters.containsKey('payment_intent');
    if (redirectStatus == 'succeeded' && hasPaymentIntent) {
      return true;
    }

    final isOrdersHost = host == 'app.lemonsqueezy.com';
    final startsWithOrders = uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == 'my-orders';
    final hasOrderSignature = uri.queryParameters.containsKey('signature');
    if (isOrdersHost && startsWithOrders && hasOrderSignature) {
      return true;
    }

    return false;
  }

  bool isHostedCheckoutCancelledLink(Uri uri) {
    if (!hasRecentPendingCheckout) {
      return false;
    }
    return uri.queryParameters['redirect_status'] == 'failed';
  }

  bool get isProActive {
    return _box.get(isProActiveKey, defaultValue: false) == true;
  }

  DateTime? get purchaseDate {
    final raw = _box.get(purchaseDateKey);
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    return null;
  }

  DateTime? get pendingCheckoutStartedAt {
    final raw = _box.get(pendingCheckoutStartedAtKey);
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    return null;
  }

  bool get hasPendingCheckout {
    final nonce = _box.get(pendingCheckoutNonceKey);
    if (nonce is String && nonce.isNotEmpty) {
      return true;
    }
    return pendingCheckoutStartedAt != null;
  }

  bool get hasRecentPendingCheckout {
    final startedAt = pendingCheckoutStartedAt;
    if (startedAt == null) {
      return false;
    }
    final age = DateTime.now().difference(startedAt);
    return age <= pendingCheckoutMaxAge;
  }

  DateTime? get expiresOn {
    final date = purchaseDate;
    if (date == null) {
      return null;
    }
    return date.add(const Duration(days: 30));
  }

  Future<void> activatePro({DateTime? purchasedAt}) async {
    final now = purchasedAt ?? DateTime.now();
    await _box.put(isProActiveKey, true);
    await _box.put(purchaseDateKey, now.millisecondsSinceEpoch);
    await _box.delete(pendingCheckoutNonceKey);
    await _box.delete(pendingCheckoutStartedAtKey);
  }

  Future<void> clearPendingCheckout() async {
    await _box.delete(pendingCheckoutNonceKey);
    await _box.delete(pendingCheckoutStartedAtKey);
  }

  Future<void> maybeExpirePro() async {
    final expiry = expiresOn;
    if (expiry == null) {
      return;
    }
    if (DateTime.now().isAfter(expiry)) {
      await _box.put(isProActiveKey, false);
      await _box.delete(purchaseDateKey);
    }
  }

  Future<Uri> createCheckoutUri() async {
    final nonce = _createCheckoutNonce();
    await _box.put(pendingCheckoutNonceKey, nonce);
    await _box.put(
      pendingCheckoutStartedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    final successDeepLink = Uri(
      scheme: deepLinkScheme,
      host: deepLinkHost,
      queryParameters: {
        'status': 'paid',
        'variant_id': variantId.toString(),
        'nonce': nonce,
      },
    );

    final cancelDeepLink = Uri(
      scheme: deepLinkScheme,
      host: deepLinkHost,
      queryParameters: {
        'status': 'cancelled',
        'variant_id': variantId.toString(),
        'nonce': nonce,
      },
    );

    final successUrl = successDeepLink.toString();
    final cancelUrl = cancelDeepLink.toString();

    return Uri.parse(checkoutUrl).replace(
      queryParameters: {
        'media': '0',
        'redirect_url': successUrl,
        'success_url': successUrl,
        'cancel_url': cancelUrl,
        'checkout[redirect_url]': successUrl,
        'checkout[success_url]': successUrl,
        'checkout[cancel_url]': cancelUrl,
        'product_options[redirect_url]': successUrl,
      },
    );
  }

  String _createCheckoutNonce() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1 << 32).toRadixString(16);
    return '$millis-$random';
  }
}

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final box = Hive.box<dynamic>(HiveBoxes.settings);
  return SubscriptionService(box);
});

final subscriptionProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(subscriptionServiceProvider);
  await service.maybeExpirePro();
  yield service.isProActive;

  await for (final _ in service.watchChanges()) {
    await service.maybeExpirePro();
    yield service.isProActive;
  }
});
