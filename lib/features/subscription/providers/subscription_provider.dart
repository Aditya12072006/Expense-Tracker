import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_boxes.dart';

const String razorpayKeyId = 'rzp_test_SdHn25UlzVmSgU';
const int premiumAmountPaise = 4900;

class SubscriptionService {
  SubscriptionService(this._box);

  static const String isProActiveKey = 'is_pro_active';
  static const String purchaseDateKey = 'pro_purchase_date_ms';
  static const String premiumExpiryDateKey = 'pro_premium_expiry_date_ms';

  final Box<dynamic> _box;

  Stream<BoxEvent> watchChanges() => _box.watch();

  bool get isProActive {
    final expiry = premiumExpiryDate;
    if (expiry == null) {
      return false;
    }
    return DateTime.now().isBefore(expiry);
  }

  DateTime? get purchaseDate {
    final raw = _box.get(purchaseDateKey);
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    return null;
  }

  DateTime? get premiumExpiryDate {
    final raw = _box.get(premiumExpiryDateKey);
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    return null;
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
    final expiry = now.add(const Duration(days: 30));
    await _box.put(purchaseDateKey, now.millisecondsSinceEpoch);
    await _box.put(premiumExpiryDateKey, expiry.millisecondsSinceEpoch);
    await _box.put(isProActiveKey, true);
  }

  Future<bool> restorePremiumPurchase() async {
    await maybeExpirePro();
    return isProActive;
  }

  Future<void> maybeExpirePro() async {
    final rawActive = _box.get(isProActiveKey, defaultValue: false) == true;
    final expiry = premiumExpiryDate;
    if (expiry == null) {
      if (rawActive) {
        await _box.put(isProActiveKey, false);
      }
      return;
    }

    if (DateTime.now().isBefore(expiry)) {
      if (!rawActive) {
        await _box.put(isProActiveKey, true);
      }
      return;
    }

    if (rawActive) {
      await _box.put(isProActiveKey, false);
      await _box.delete(purchaseDateKey);
      await _box.delete(premiumExpiryDateKey);
    }
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
