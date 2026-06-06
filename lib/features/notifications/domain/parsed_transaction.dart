/// Direction of a detected transaction relative to the user's balance.
enum TxnDirection { income, expense }

/// Which engine produced a parse result (for confidence/telemetry).
enum ParseSource { regex, ai }

/// A transaction extracted from a notification's text. `amountMagnitude` is
/// always positive; [signedAmount] applies the direction (expense = negative)
/// to match the wallet's signed-amount convention.
class ParsedTransaction {
  const ParsedTransaction({
    required this.amountMagnitude,
    required this.direction,
    this.currency = 'AZN',
    this.rawMatch,
    this.description,
    this.confidence = 0,
    this.source = ParseSource.regex,
  });

  final double amountMagnitude;
  final TxnDirection direction;
  final String currency;
  final String? rawMatch;
  final String? description;
  final double confidence; // 0..1
  final ParseSource source;

  double get signedAmount =>
      direction == TxnDirection.expense ? -amountMagnitude : amountMagnitude;
}
