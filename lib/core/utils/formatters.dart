import 'package:intl/intl.dart';

final NumberFormat _money = NumberFormat('#,##0.00', 'tr_TR');
final DateFormat _date = DateFormat('d MMM y', 'tr_TR');
final DateFormat _dayHeader = DateFormat('d MMMM y', 'tr_TR');
final DateFormat _clock = DateFormat('HH:mm', 'tr_TR');

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

String formatTime(DateTime date) => _clock.format(date);

/// Compact relative time for notification headers: "Simdi" / "5 dk" /
/// "2 sa" / "Dun" / full date for older items.
String formatRelativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Simdi';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk';
  if (diff.inHours < 24) return '${diff.inHours} sa';
  if (diff.inDays == 1) return 'Dun';
  if (diff.inDays < 7) return '${diff.inDays} gun';
  return _date.format(date);
}
