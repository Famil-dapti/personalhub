import 'package:flutter/material.dart';

/// Corner radii tokens (see docs/design/personalhub/specs/00 - Tokens.md).
abstract final class AppRadii {
  static const double chip = 12;
  static const double field = 12;
  static const double card = 18;
  static const double sheet = 24;
  static const double dialog = 28;
  static const double balance = 24;
  static const double avatar = 14;
  static const double pill = 999;

  static const BorderRadius chipR = BorderRadius.all(Radius.circular(chip));
  static const BorderRadius fieldR = BorderRadius.all(Radius.circular(field));
  static const BorderRadius cardR = BorderRadius.all(Radius.circular(card));
  static const BorderRadius sheetR = BorderRadius.all(Radius.circular(sheet));
  static const BorderRadius balanceR =
      BorderRadius.all(Radius.circular(balance));
  static const BorderRadius pillR = BorderRadius.all(Radius.circular(pill));
}

/// Elevation tokens. `elev1` rows/cards, `elev2` frames, `elev3` FAB/sheet/dialog.
abstract final class AppElevation {
  static const double elev0 = 0;
  static const double elev1 = 1;
  static const double elev2 = 3;
  static const double elev3 = 6;
}

/// Tabular figures so amounts align in columns (`1.234,56 AZN`).
const List<FontFeature> kTabularFigures = [FontFeature.tabularFigures()];

/// Semantic money colors that the Material 3 [ColorScheme] does not express.
/// Income = green; expense maps to `error` red (read from the scheme directly).
/// Registered on both light and dark themes so widgets stay dark-safe via
/// `Theme.of(context).money`.
@immutable
class MoneyColors extends ThemeExtension<MoneyColors> {
  const MoneyColors({
    required this.income,
    required this.onIncome,
    required this.incomeContainer,
  });

  final Color income;
  final Color onIncome;
  final Color incomeContainer;

  static const light = MoneyColors(
    income: Color(0xFF2E7D52),
    onIncome: Color(0xFFFFFFFF),
    incomeContainer: Color(0xFFB6F2D2),
  );

  static const dark = MoneyColors(
    income: Color(0xFF7CDBA6),
    onIncome: Color(0xFF00391F),
    incomeContainer: Color(0xFF1E4733),
  );

  @override
  MoneyColors copyWith({
    Color? income,
    Color? onIncome,
    Color? incomeContainer,
  }) {
    return MoneyColors(
      income: income ?? this.income,
      onIncome: onIncome ?? this.onIncome,
      incomeContainer: incomeContainer ?? this.incomeContainer,
    );
  }

  @override
  MoneyColors lerp(ThemeExtension<MoneyColors>? other, double t) {
    if (other is! MoneyColors) return this;
    return MoneyColors(
      income: Color.lerp(income, other.income, t)!,
      onIncome: Color.lerp(onIncome, other.onIncome, t)!,
      incomeContainer: Color.lerp(incomeContainer, other.incomeContainer, t)!,
    );
  }
}

/// Convenience accessors for the custom theme extension and money roles.
extension MoneyTheme on ThemeData {
  MoneyColors get money => extension<MoneyColors>() ?? MoneyColors.light;
}

extension MoneyContext on BuildContext {
  MoneyColors get money => Theme.of(this).money;
}
