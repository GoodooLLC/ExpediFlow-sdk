// Утилиты форматирования

import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '',
    decimalDigits: 2,
  );

  static final _quantityFormat = NumberFormat('#,##0.##', 'ru_RU');

  // Форматировать сумму: 15 750,00
  static String currency(double value) => _currencyFormat.format(value).trim();

  // Форматировать количество: 10, 1,5
  static String quantity(double value) => _quantityFormat.format(value);

  // Форматировать дату из строки ISO
  static String date(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('dd.MM.yyyy', 'ru_RU').format(dt);
    } catch (_) {
      return isoDate;
    }
  }
}
