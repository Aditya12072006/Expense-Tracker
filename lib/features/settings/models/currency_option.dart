class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.label,
  });

  final String code;
  final String symbol;
  final String label;
}

const List<CurrencyOption> kCurrencyOptions = [
  CurrencyOption(code: 'USD', symbol: r'$', label: 'US Dollar'),
  CurrencyOption(code: 'INR', symbol: '₹', label: 'Indian Rupee'),
  CurrencyOption(code: 'EUR', symbol: '€', label: 'Euro'),
  CurrencyOption(code: 'GBP', symbol: '£', label: 'British Pound'),
  CurrencyOption(code: 'JPY', symbol: '¥', label: 'Japanese Yen'),
  CurrencyOption(code: 'AUD', symbol: r'A$', label: 'Australian Dollar'),
  CurrencyOption(code: 'CAD', symbol: r'C$', label: 'Canadian Dollar'),
  CurrencyOption(code: 'NPR', symbol: 'Rs', label: 'Nepalese Rupee'),
];

const CurrencyOption kDefaultCurrency = CurrencyOption(
  code: 'USD',
  symbol: r'$',
  label: 'US Dollar',
);

CurrencyOption currencyByCode(String? code) {
  if (code == null) {
    return kDefaultCurrency;
  }
  return kCurrencyOptions.firstWhere(
    (item) => item.code == code,
    orElse: () => kDefaultCurrency,
  );
}
