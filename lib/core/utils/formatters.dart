import 'package:intl/intl.dart';

final NumberFormat _money = NumberFormat('#,##0.00', 'tr_TR');
final DateFormat _date = DateFormat('d MMM y', 'tr_TR');

// Phase 1.1: single currency (AZN). Symbol appended manually.
String formatMoney(double amount) => '${_money.format(amount)} AZN';

String formatSignedMoney(double amount) {
  final sign = amount >= 0 ? '+' : '-';
  return '$sign${_money.format(amount.abs())} AZN';
}

String formatDate(DateTime date) => _date.format(date);
