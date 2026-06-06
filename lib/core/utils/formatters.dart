import 'package:intl/intl.dart';

final NumberFormat _money = NumberFormat('#,##0.00', 'tr_TR');
final DateFormat _date = DateFormat('d MMM y', 'tr_TR');
final DateFormat _dayHeader = DateFormat('d MMMM y', 'tr_TR');

// Phase 1.1: single currency (AZN). Symbol appended manually.
String formatMoney(double amount) => '${_money.format(amount)} AZN';

String formatSignedMoney(double amount) {
  final sign = amount >= 0 ? '+' : '-';
  return '$sign${_money.format(amount.abs())} AZN';
}

String formatDate(DateTime date) => _date.format(date);

/// Calendar-day key (year/month/day) for grouping transactions into sections.
DateTime dayKey(DateTime date) => DateTime(date.year, date.month, date.day);

/// Section header label for a transaction group: "Bugun" / "Dun" / full date.
String formatDayHeader(DateTime date) {
  final today = dayKey(DateTime.now());
  final day = dayKey(date);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Bugun';
  if (diff == 1) return 'Dun';
  return _dayHeader.format(date);
}
