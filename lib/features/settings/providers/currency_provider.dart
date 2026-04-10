import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_boxes.dart';
import '../models/currency_option.dart';

class CurrencyNotifier extends Notifier<CurrencyOption> {
  static const String _currencyKey = 'currency_code';

  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.settings);

  @override
  CurrencyOption build() {
    final raw = _box.get(_currencyKey);
    return currencyByCode(raw is String ? raw : null);
  }

  void setCurrency(String code) {
    final selected = currencyByCode(code);
    _box.put(_currencyKey, selected.code);
    state = selected;
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, CurrencyOption>(
  CurrencyNotifier.new,
);
