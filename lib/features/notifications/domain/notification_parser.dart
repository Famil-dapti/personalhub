import 'diacritics.dart';
import 'package_templates.dart';
import 'parsed_transaction.dart';

/// Device-side notification -> transaction parser (free, offline, private).
///
/// Strategy: route by package to a bank template; if the template defers, fall
/// back to a generic amount/currency/direction extractor. Keyword sets cover
/// both diacritic and ASCII-folded spellings (banks send either). Returns null
/// when no money signal is found.

// Keywords already in folded (ASCII + lowercase) form. Both 'e' and 'a'
// transliterations are listed because banks are inconsistent (mədaxil may
// arrive as "medaxil" or "madaxil").
const List<String> _incomeKeywords = [
  'medaxil', 'madaxil', 'daxilolma', 'daxil oldu', 'kocuruldu', 'kocurme',
  'kesbek', 'maas', 'burs', 'hesabiniza', 'received', 'credit', 'refund',
];
const List<String> _expenseKeywords = [
  'mexaric', 'maxaric', 'odenis', 'odeme', 'odendi', 'alis', 'cixaris',
  'paid', 'payment', 'debit', 'purchase', 'spent',
];
const List<String> _currencyTokens = ['azn', '₼', 'man.', 'manat', 'usd', 'eur'];
const List<String> _bankingContext = [
  'kart', 'hesab', 'balans', 'mebleg', 'transfer', 'terminal',
];

// Integer part allows space/nbsp thousands grouping; decimals are dot or comma.
final RegExp _amountPattern =
    RegExp('(\\d{1,3}(?:[  ]\\d{3})+|\\d+)([.,]\\d{1,2})?');
final RegExp _thousandsSep = RegExp('[  ]');

/// Top-level parse: package template first, then the generic fallback.
ParsedTransaction? parseNotification({
  String? appPackage,
  String? title,
  String? body,
}) {
  final viaTemplate = templateFor(appPackage)?.tryParse(title, body);
  if (viaTemplate != null) return viaTemplate;
  return _genericParse(title, body);
}

/// Lenient amount extraction for the SMS auto-route: any amount becomes a
/// draft (direction best-effort, defaults to expense). Caller has already
/// applied the strict NN.NN gate, so we do not require a currency/keyword.
ParsedTransaction? parseAmountLenient(String? title, String? body) {
  final text = '${title ?? ''} ${body ?? ''}'.trim();
  if (text.isEmpty) return null;
  final folded = foldAndLower(text);
  final amount = _extractAmount(_stripDatesAndTimes(folded));
  if (amount == null) return null;
  return ParsedTransaction(
    amountMagnitude: amount,
    direction: _inferDirection(folded),
    confidence: 0.5,
  );
}

ParsedTransaction? _genericParse(String? title, String? body) {
  final original = '${title ?? ''} ${body ?? ''}'.trim();
  if (original.isEmpty) return null;
  final folded = foldAndLower(original);
  final cleaned = _stripDatesAndTimes(folded);

  final amount = _extractAmount(cleaned);
  if (amount == null) return null;

  final hasCurrency = _currencyTokens.any(folded.contains);
  final hasKeyword = _incomeKeywords.any(folded.contains) ||
      _expenseKeywords.any(folded.contains);
  final hasContext = _bankingContext.any(folded.contains);
  // A bare number is not enough — require a money signal to avoid flagging
  // ids/codes/quantities as transactions.
  if (!hasCurrency && !hasKeyword && !hasContext) return null;

  return ParsedTransaction(
    amountMagnitude: amount,
    direction: _inferDirection(folded),
    currency: 'AZN', // single-currency wallet (Phase 1.1)
    description: title,
    confidence: _scoreConfidence(hasCurrency: hasCurrency, hasKeyword: hasKeyword),
  );
}

// Remove dates, times, and masked card tails so their digits are never
// mistaken for the amount (e.g. "06.06.2026" or "*1234").
String _stripDatesAndTimes(String text) {
  return text
      .replaceAll(RegExp(r'\d{1,4}[./-]\d{1,2}[./-]\d{1,4}'), ' ')
      .replaceAll(RegExp(r'\d{1,2}:\d{2}(?::\d{2})?'), ' ')
      .replaceAll(RegExp(r'\*+\d{2,4}'), ' ');
}

double? _extractAmount(String text) {
  final matches = _amountPattern.allMatches(text).toList();
  if (matches.isEmpty) return null;
  // Prefer a decimal-bearing match (money is "NN.NN"); else the first number.
  final best = matches.firstWhere(
    (m) => m.group(2) != null,
    orElse: () => matches.first,
  );
  final intPart = best.group(1)!.replaceAll(_thousandsSep, '');
  final decGroup = best.group(2);
  final decimals = decGroup == null ? '' : '.${decGroup.substring(1)}';
  return double.tryParse('$intPart$decimals');
}

TxnDirection _inferDirection(String folded) {
  final isIncome = _incomeKeywords.any(folded.contains);
  final isExpense = _expenseKeywords.any(folded.contains);
  if (isIncome && !isExpense) return TxnDirection.income;
  if (isExpense && !isIncome) return TxnDirection.expense;
  // Ambiguous or unmarked: default to expense (most bank pushes are debits).
  return TxnDirection.expense;
}

double _scoreConfidence({required bool hasCurrency, required bool hasKeyword}) {
  if (hasCurrency && hasKeyword) return 0.9;
  if (hasCurrency || hasKeyword) return 0.6;
  return 0.3;
}
