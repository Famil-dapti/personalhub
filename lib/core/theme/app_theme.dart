import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// PersonalHub Material 3 theme.
///
/// Implements the design tokens in `docs/design/personalhub/specs/00 - Tokens.md`:
/// a deep teal/green ("money-forward") scheme replacing the original purple seed,
/// the Inter typeface with explicit role sizing, and shared radii/elevation.
class AppTheme {
  AppTheme._();

  // --- Color schemes (explicit M3 roles from the tokens spec) ---------------

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0B6E4F),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF9FF2CC),
    onPrimaryContainer: Color(0xFF00210F),
    secondary: Color(0xFF4C6358),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCEE9DA),
    onSecondaryContainer: Color(0xFF092017),
    tertiary: Color(0xFF3D6373),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFC0E9FB),
    onTertiaryContainer: Color(0xFF001F2A),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF6FBF6),
    onSurface: Color(0xFF171D19),
    onSurfaceVariant: Color(0xFF404943),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF0F6F0),
    surfaceContainer: Color(0xFFEAF1EB),
    surfaceContainerHigh: Color(0xFFE5EBE5),
    surfaceContainerHighest: Color(0xFFDFE5E0),
    surfaceDim: Color(0xFFD6DCD7),
    surfaceBright: Color(0xFFF6FBF6),
    outline: Color(0xFF707972),
    outlineVariant: Color(0xFFC0C9C0),
    inverseSurface: Color(0xFF2B322D),
    onInverseSurface: Color(0xFFECF2EC),
    inversePrimary: Color(0xFF73DBAE),
    surfaceTint: Color(0xFF0B6E4F),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF73DBAE),
    onPrimary: Color(0xFF003824),
    primaryContainer: Color(0xFF005138),
    onPrimaryContainer: Color(0xFF8FF7CE),
    secondary: Color(0xFFB2CCBE),
    onSecondary: Color(0xFF1E352B),
    secondaryContainer: Color(0xFF344B40),
    onSecondaryContainer: Color(0xFFCEE9DA),
    tertiary: Color(0xFFA4CDDF),
    onTertiary: Color(0xFF053543),
    tertiaryContainer: Color(0xFF244C5B),
    onTertiaryContainer: Color(0xFFC0E9FB),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF0F140F),
    onSurface: Color(0xFFDEE4DF),
    onSurfaceVariant: Color(0xFFBFC9C0),
    surfaceContainerLowest: Color(0xFF0A0F0A),
    surfaceContainerLow: Color(0xFF171D18),
    surfaceContainer: Color(0xFF1B211C),
    surfaceContainerHigh: Color(0xFF252B26),
    surfaceContainerHighest: Color(0xFF303631),
    surfaceDim: Color(0xFF0F140F),
    surfaceBright: Color(0xFF353B36),
    outline: Color(0xFF8A938B),
    outlineVariant: Color(0xFF404943),
    inverseSurface: Color(0xFFDEE4DF),
    onInverseSurface: Color(0xFF2B322D),
    inversePrimary: Color(0xFF0B6E4F),
    surfaceTint: Color(0xFF73DBAE),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  // --- Typography (Material 3 roles, Inter, explicit sizing) ----------------

  static TextTheme _textTheme(ColorScheme scheme) {
    final base = GoogleFonts.interTextTheme(
      scheme.brightness == Brightness.dark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme,
    );
    TextStyle? role(TextStyle? s, double size, double lineHeight, FontWeight w) {
      return s?.copyWith(
        fontSize: size,
        height: lineHeight / size,
        fontWeight: w,
        letterSpacing: 0,
      );
    }

    return base.copyWith(
      headlineMedium: role(base.headlineMedium, 28, 34, FontWeight.w600),
      headlineSmall: role(base.headlineSmall, 24, 30, FontWeight.w600),
      titleLarge: role(base.titleLarge, 20, 26, FontWeight.w600),
      titleMedium: role(base.titleMedium, 16, 22, FontWeight.w600),
      titleSmall: role(base.titleSmall, 14, 20, FontWeight.w600),
      labelLarge: role(base.labelLarge, 14, 18, FontWeight.w600),
      labelMedium: role(base.labelMedium, 12, 16, FontWeight.w600),
      labelSmall: role(base.labelSmall, 11, 16, FontWeight.w600),
      bodyLarge: role(base.bodyLarge, 16, 24, FontWeight.w400),
      bodyMedium: role(base.bodyMedium, 14, 20, FontWeight.w400),
      bodySmall: role(base.bodySmall, 12, 16, FontWeight.w400),
    );
  }

  // --- Theme assembly -------------------------------------------------------

  static ThemeData _build(ColorScheme scheme, MoneyColors money) {
    final textTheme = _textTheme(scheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      extensions: [money],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: AppElevation.elev2,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: AppElevation.elev1,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shadowColor: scheme.shadow.withValues(alpha: 0.10),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.cardR),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        elevation: AppElevation.elev2,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        elevation: 0,
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle:
            textTheme.labelMedium?.copyWith(color: scheme.onSurface),
        unselectedLabelTextStyle:
            textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.fieldR),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.fieldR),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: AppElevation.elev3,
        extendedTextStyle: textTheme.labelLarge,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.fieldR),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.chipR),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: textTheme.labelMedium,
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.secondaryContainer,
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: const OutlineInputBorder(
          borderRadius: AppRadii.fieldR,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.fieldR,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.fieldR,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.dialog),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
        ),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get light => _build(_lightScheme, MoneyColors.light);
  static ThemeData get dark => _build(_darkScheme, MoneyColors.dark);
}
