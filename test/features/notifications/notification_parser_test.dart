import 'package:flutter_test/flutter_test.dart';
import 'package:personalhub/features/notifications/domain/notification_parser.dart';
import 'package:personalhub/features/notifications/domain/parsed_transaction.dart';

void main() {
  group('parseNotification', () {
    test('reads AZN income with dot decimals', () {
      final r = parseNotification(body: 'Hesabiniza 150.00 AZN medaxil');
      expect(r, isNotNull);
      expect(r!.amountMagnitude, 150.00);
      expect(r.direction, TxnDirection.income);
      expect(r.signedAmount, 150.00);
    });

    test('reads AZN expense', () {
      final r = parseNotification(body: 'Kartdan 25.50 AZN mexaric');
      expect(r!.amountMagnitude, 25.50);
      expect(r.direction, TxnDirection.expense);
      expect(r.signedAmount, -25.50);
    });

    test('handles the manat glyph with space-grouped thousands (Leobank)', () {
      final r = parseNotification(body: 'Hesabiniza 15 000.00 ₼ daxil oldu');
      expect(r!.amountMagnitude, 15000.00);
      expect(r.direction, TxnDirection.income);
    });

    test('normalizes a comma decimal separator', () {
      final r = parseNotification(body: '150,00 AZN odenis');
      expect(r!.amountMagnitude, 150.00);
      expect(r.direction, TxnDirection.expense);
    });

    test('ignores dates/times and picks the real amount', () {
      final r = parseNotification(
          body: 'Tarix: 06.06.2026 14:32, mexaric 25.00 AZN');
      expect(r!.amountMagnitude, 25.00);
    });

    test('matches diacritic spelling via folding', () {
      final r = parseNotification(body: 'Mədaxil 100.00 AZN');
      expect(r!.direction, TxnDirection.income);
      expect(r.amountMagnitude, 100.00);
    });

    test('defaults to expense when direction is unmarked', () {
      final r = parseNotification(body: '40.00 AZN terminal');
      expect(r!.direction, TxnDirection.expense);
    });

    test('returns null for a bare number with no money signal', () {
      expect(parseNotification(body: 'Tesdiq kodu: 1234'), isNull);
    });

    test('returns null for empty input', () {
      expect(parseNotification(title: '', body: ''), isNull);
      expect(parseNotification(), isNull);
    });
  });

  group('parseAmountLenient (SMS auto-route)', () {
    test('extracts an amount without requiring a keyword', () {
      final r = parseAmountLenient(null, '500.00 hesabiniza kocuruldu');
      expect(r!.amountMagnitude, 500.00);
      expect(r.direction, TxnDirection.income);
    });

    test('reads a salary SMS as income', () {
      final r = parseAmountLenient(null, 'Maasiniz 800.00 AZN');
      expect(r!.direction, TxnDirection.income);
      expect(r.amountMagnitude, 800.00);
    });

    test('returns null when there is no amount', () {
      expect(parseAmountLenient(null, 'Salam, nece sen?'), isNull);
    });
  });
}
