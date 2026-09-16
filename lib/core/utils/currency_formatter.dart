import 'package:intl/intl.dart';

final NumberFormat _currencyFormatter = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

final NumberFormat _decimalFormatter = NumberFormat.decimalPattern('id');

/// Formats a number as Indonesian Rupiah currency: e.g. 4000 -> "Rp 4.000"
String formatCurrency(num amount) {
  return _currencyFormatter.format(amount);
}

/// Formats a number with dot thousand separators: e.g. 4000 -> "4.000"
String formatNumber(num number) {
  return _decimalFormatter.format(number);
}
