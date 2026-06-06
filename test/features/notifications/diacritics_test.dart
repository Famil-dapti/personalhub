import 'package:flutter_test/flutter_test.dart';
import 'package:personalhub/features/notifications/domain/diacritics.dart';

void main() {
  group('foldAndLower', () {
    test('folds Azerbaijani direction keywords to ASCII + lowercase', () {
      expect(foldAndLower('Mədaxil'), 'medaxil');
      expect(foldAndLower('Məxaric'), 'mexaric');
      expect(foldAndLower('ÖDƏNİŞ'), 'odenis');
      expect(foldAndLower('Çıxarış'), 'cixaris');
      expect(foldAndLower('Hesabınıza'), 'hesabiniza');
    });

    test('keeps the manat glyph (matched as a currency token)', () {
      expect(foldAndLower('100 ₼'), '100 ₼');
    });

    test('is a no-op for plain ASCII', () {
      expect(foldAndLower('25.00 AZN'), '25.00 azn');
    });
  });
}
