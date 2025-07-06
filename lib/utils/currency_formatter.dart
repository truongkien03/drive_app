import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  /// Format number to Vietnamese currency
  static String format(num value) {
    return _formatter.format(value);
  }

  /// Format with custom symbol
  static String formatWithSymbol(num value, String symbol) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: symbol,
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  /// Format without symbol
  static String formatWithoutSymbol(num value) {
    final formatter = NumberFormat.decimalPattern('vi_VN');
    return formatter.format(value);
  }

  /// Parse currency string to double
  static double? parse(String value) {
    try {
      // Remove currency symbols and spaces
      String cleaned =
          value.replaceAll('₫', '').replaceAll(' ', '').replaceAll(',', '');

      return double.tryParse(cleaned);
    } catch (e) {
      return null;
    }
  }
}
