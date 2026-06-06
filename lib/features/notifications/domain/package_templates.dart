import 'parsed_transaction.dart';

/// Android package names of the transaction sources we route (the primary,
/// most reliable detection signal — far more stable than message text).
const String kPkgKapital = 'az.kapitalbank.mbanking'; // Kapital Bank / Birbank
const String kPkgAbb = 'iba.mobilbank'; // ABB mobile (Azericard backend)
const String kPkgLeobank = 'com.ftfarm.leo';
const String kPkgM10 = 'com.m10';
const String kPkgGooglePay = 'com.google.android.apps.walletnfcrel';
const String kPkgGms = 'com.google.android.gms'; // Google Pay tap-to-pay summary

/// SMS / messaging apps whose notification body can carry a bank alert (salary,
/// scholarship, card movement). Used for the SMS auto-route rule.
const Set<String> kSmsPackages = {
  'com.google.android.apps.messaging',
  'com.samsung.android.messaging',
  'com.android.messaging',
  'com.android.mms',
  'com.miui.smsextra',
};

/// Packages routed as potential transaction sources (banks + wallets).
const Set<String> kBankPackages = {
  kPkgKapital,
  kPkgAbb,
  kPkgLeobank,
  kPkgM10,
  kPkgGooglePay,
  kPkgGms,
};

/// A per-bank parsing template. Subclasses refine extraction once real
/// notification samples are captured on-device; until then they defer to the
/// generic parser by returning null. The routing scaffold is in place so a
/// bank-specific template can be slotted in without touching the parser.
abstract class BankTemplate {
  const BankTemplate();
  ParsedTransaction? tryParse(String? title, String? body);
}

/// Placeholder template: no bank-specific rules yet, defer to generic parsing.
class _DeferTemplate extends BankTemplate {
  const _DeferTemplate();
  @override
  ParsedTransaction? tryParse(String? title, String? body) => null;
}

const Map<String, BankTemplate> _templates = {
  kPkgKapital: _DeferTemplate(),
  kPkgAbb: _DeferTemplate(),
  kPkgLeobank: _DeferTemplate(),
  kPkgM10: _DeferTemplate(),
  kPkgGooglePay: _DeferTemplate(),
  kPkgGms: _DeferTemplate(),
};

BankTemplate? templateFor(String? appPackage) =>
    appPackage == null ? null : _templates[appPackage];
