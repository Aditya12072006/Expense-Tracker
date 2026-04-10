import 'package:intl/intl.dart';

String formatMoney(
    double value, {
    required String currencyCode,
    required String currencySymbol,
}) {
    return NumberFormat.currency(
        name: currencyCode,
        symbol: currencySymbol,
        decimalDigits: 2,
    ).format(value);
}

String formatTransactionDate(DateTime date) =>
    DateFormat('d MMM, h:mm a').format(date);