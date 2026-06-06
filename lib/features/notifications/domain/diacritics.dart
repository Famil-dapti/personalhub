// Azerbaijani/Turkish diacritic folding for parser keyword matching.
//
// Bank notifications arrive with or without special characters (the same
// alert may be "medaxil" or "medaxil"), so we fold to ASCII + lowercase
// before any keyword/currency comparison.

const Map<String, String> _foldMap = {
  'ç': 'c', 'Ç': 'c',
  'ş': 's', 'Ş': 's',
  'ğ': 'g', 'Ğ': 'g',
  'ı': 'i', 'I': 'i', 'İ': 'i',
  'ö': 'o', 'Ö': 'o',
  'ü': 'u', 'Ü': 'u',
  'ə': 'e', 'Ə': 'e',
};

/// Folds AZ/TR diacritics to ASCII and lowercases. The currency glyph `₼` is
/// left intact (it is matched as a currency token, not folded).
String foldAndLower(String input) {
  final buffer = StringBuffer();
  for (final char in input.split('')) {
    buffer.write(_foldMap[char] ?? char);
  }
  return buffer.toString().toLowerCase();
}
