import 'package:flutter/material.dart';

/// The app's palette: the Daaya logo's three colours, given jobs.
///
/// **Not a Material Theme Builder export, and that is the one deliberate departure from
/// RULES §7.** The staff app's `theme.dart` is generated from a seed colour and replaced
/// wholesale; this one is written from the logo's own hexes, because the logo *has* them and a
/// seed would only approximate them. Feeding `#D5D74D` to the generator produces an olive
/// scheme, not the yellow the logo is built on.
///
/// The rule the generated file exists to protect still holds: **no screen in this app writes a
/// `Color(0xff…)`.** Every hex in the product lives here or in `app_tones.dart`, once. Changing
/// the palette is changing these two files and nothing else.
///
/// The logo, sampled from `assets/images/logo.png`:
///
/// | Logo | Hex | Job |
/// |---|---|---|
/// | the filled square | `#D5D74D` yellow | **fills**: buttons, selected chips, the main action |
/// | the left outline | `#4C29D0` purple | **lines and ink** in daylight; the account card; the header band's hue |
/// | the right outline | `#57937F` green | «done»: paid, delivered (`PaymentTone`) |
///
/// **Yellow is the brand, and yellow cannot be ink on white.** `#D5D74D` on white is 1.4 to 1;
/// no amount of care makes a yellow link or a yellow price readable in daylight. The logo already
/// answers this, by drawing yellow as a *fill* and purple as the *line* around it, and the
/// scheme does the same:
///
///   * `primaryContainer` is the yellow in **both** appearances, with dark ink on it. Every
///     filled thing in the app takes it: `AppButton`, the speed dial, selected chips, the
///     component themes below.
///   * `primary` is what an accent *line or text* is drawn in: the yellow at night, where it
///     reads at 12 to 1 on the page, and the logo's purple by day, where it reads at 7.7 to 1.
///
/// In the dark the two roles are the same colour, so nothing there looks split.
class MaterialTheme {
  const MaterialTheme(this.textTheme);

  final TextTheme textTheme;

  /// The night palette: the logo's yellow on surfaces of a very dark indigo, taken from the
  /// purple outline's own hue (253°) so the page reads as Daaya rather than as neutral grey.
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,

    // The yellow does both jobs at night: it is legible on the page, and dark ink is legible on
    // it.
    primary: Color(0xffd5d74d),
    onPrimary: Color(0xff15122b),
    primaryContainer: Color(0xffd5d74d),
    onPrimaryContainer: Color(0xff15122b),

    // A lavender tint of the logo's purple, for what is present but not shouting.
    secondary: Color(0xffb4aaf2),
    onSecondary: Color(0xff1e1650),
    secondaryContainer: Color(0xff2c2565),
    onSecondaryContainer: Color(0xffdcd6ff),

    // Warning orange, and the one colour not taken from the logo: it carries the warning snack
    // and dialog, and «اطلب أكثر وينزل السعر». It sits 33° from the yellow so a warning never
    // reads as the app's own call to action.
    tertiary: Color(0xfff2994a),
    onTertiary: Color(0xff2b1600),
    tertiaryContainer: Color(0xff5a3311),
    onTertiaryContainer: Color(0xffffdcc2),

    error: Color(0xffffb4ab),
    onError: Color(0xff690005),
    errorContainer: Color(0xff93000a),
    onErrorContainer: Color(0xffffdad6),

    surface: Color(0xff110e24),
    onSurface: Color(0xffeceaf6),
    onSurfaceVariant: Color(0xffa8a3c6),
    surfaceTint: Color(0xffd5d74d),

    surfaceDim: Color(0xff0b0919),
    surfaceBright: Color(0xff353060),
    surfaceContainerLowest: Color(0xff0b0919),
    surfaceContainerLow: Color(0xff16132e),
    surfaceContainer: Color(0xff1b1837),
    surfaceContainerHigh: Color(0xff231f45),
    surfaceContainerHighest: Color(0xff2c2852),

    // `outline` is what a border has to be *seen*; `outlineVariant` is the card hairline.
    outline: Color(0xff6e6894),
    outlineVariant: Color(0xff2c2852),

    shadow: Color(0xff000000),
    scrim: Color(0xff000000),

    inverseSurface: Color(0xffeceaf6),
    onInverseSurface: Color(0xff15122b),
    inversePrimary: Color(0xff5e6000),
  );

  /// The day palette: the logo as it is printed, on white.
  ///
  ///   * **`primaryContainer` does not move.** The yellow is the brand; it is the fill of every
  ///     button and selected chip at both times of day, with the same dark ink on it.
  ///   * **`primary` becomes the logo's purple.** See the class doc: this is the role text and
  ///     lines are drawn in, and yellow cannot do it on white.
  ///   * **The indigo becomes the ink.** `#15122B` is the ink on yellow at night and the body
  ///     text by day, so the yellow carries the same ink in both appearances.
  ///   * **The surface ladder climbs the other way.** Dark stacks indigo upward from the page;
  ///     light stacks lavender-grey downward from white, so a card is still one step from the
  ///     page and a border is still one step from the card.
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,

    primary: Color(0xff4c29d0),
    onPrimary: Color(0xffffffff),
    primaryContainer: Color(0xffd5d74d),
    onPrimaryContainer: Color(0xff15122b),

    secondary: Color(0xff5c5784),
    onSecondary: Color(0xffffffff),
    secondaryContainer: Color(0xffe6e2f8),
    onSecondaryContainer: Color(0xff2b2560),

    tertiary: Color(0xff9a4a00),
    onTertiary: Color(0xffffffff),
    tertiaryContainer: Color(0xffffdcc2),
    onTertiaryContainer: Color(0xff321300),

    error: Color(0xffba1a1a),
    onError: Color(0xffffffff),
    errorContainer: Color(0xffffdad6),
    onErrorContainer: Color(0xff410002),

    surface: Color(0xfff7f6fb),
    onSurface: Color(0xff15122b),
    onSurfaceVariant: Color(0xff5c5880),
    surfaceTint: Color(0xff4c29d0),

    surfaceDim: Color(0xffdddbe8),
    surfaceBright: Color(0xffffffff),
    surfaceContainerLowest: Color(0xffffffff),
    surfaceContainerLow: Color(0xffffffff),
    surfaceContainer: Color(0xfff0eff7),
    surfaceContainerHigh: Color(0xffe8e6f2),
    surfaceContainerHighest: Color(0xffdddaec),

    // Same division of labour as the dark scheme: `outline` is a border meant to be seen,
    // `outlineVariant` is the card hairline.
    outline: Color(0xff8c88aa),
    outlineVariant: Color(0xffdddaec),

    shadow: Color(0xff000000),
    scrim: Color(0xff000000),

    inverseSurface: Color(0xff15122b),
    onInverseSurface: Color(0xffeceaf6),
    inversePrimary: Color(0xffd5d74d),
  );

  ThemeData dark() => theme(darkScheme);

  ThemeData light() => theme(lightScheme);

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,

    // ── the design's component grammar, set once ─────────────────────────────
    //
    // Written here rather than in each screen for the reason the colours are: these are
    // decisions the design made about the whole app, and a radius typed into a widget is a
    // radius that stops matching the moment somebody changes their mind.
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),

    // The raised strip with a hairline above it, and the active item in the accent.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      indicatorColor: Colors.transparent,
      elevation: 0,
      height: 74,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
      ),
    ),

    // Cards: the container step inside a hairline, 20px corners.
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),

    // 52px tall, 16px corners: the design's one button. Filled with the yellow at both times of
    // day, which is why it names `primaryContainer` and not Material's default `primary`.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
    ),

    // Filter chips: 38px, 12px corners, the container step with a hairline, and solid yellow
    // once chosen.
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      selectedColor: colorScheme.primaryContainer,
      side: BorderSide(color: colorScheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      secondaryLabelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: colorScheme.onPrimaryContainer,
      ),
      showCheckmark: false,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
    ),

    dividerTheme: DividerThemeData(color: colorScheme.outlineVariant, thickness: 1),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(color: colorScheme.primary),
  );
}
