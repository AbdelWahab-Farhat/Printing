import 'package:flutter/material.dart';

/// The app's palette.
///
/// **Not a Material Theme Builder export, and that is the one deliberate departure from
/// RULES §7.** The staff app's `theme.dart` is generated from a seed colour and replaced
/// wholesale; this one is written from the design's own hexes, because the design *has* them and
/// a seed would only approximate them. Feeding `#F4622A` to the generator produces a warm grey
/// dark scheme, not the navy the mockup is built on — the surfaces are a second decision the
/// designer made, and a seed cannot carry it.
///
/// The rule the generated file exists to protect still holds and still matters: **no screen in
/// this app writes a `Color(0xff…)`.** Every hex in the product lives here, once. Changing the
/// palette is changing this file and nothing else.
///
/// The mapping, so the next person can check it against the design rather than guess:
///
/// | Design | Role |
/// |---|---|
/// | `#0F2138` page background | `surface` |
/// | `#132A43` nav bar, raised strip | `surfaceContainerLow` |
/// | `#16304A` cards, chips | `surfaceContainer` |
/// | `#1D3C5A` | `surfaceContainerHigh` |
/// | `#24425F` card borders | `surfaceContainerHighest`, `outlineVariant` |
/// | `#E8EEF5` body text | `onSurface` |
/// | `#8FA3BA` secondary text | `onSurfaceVariant` |
/// | `#F4622A` buttons, selected chips, active tab | `primary` |
///
/// **`primaryContainer` is the solid orange, not a muted tone.** Material's convention is a
/// desaturated container behind `onPrimaryContainer` text, but the design fills a selected chip
/// with `#F4622A` and puts white on it — and selected chips are the most common use of the pair
/// in this app. Following the convention here would mean every chip in the app disagreeing with
/// every chip in the design.
class MaterialTheme {
  const MaterialTheme(this.textTheme);

  final TextTheme textTheme;

  /// The design's palette, and the only scheme this app ships.
  ///
  /// **There is no light scheme yet, deliberately.** The mockup specifies one appearance; a
  /// light palette invented here would be a set of colours nobody chose, and every screen would
  /// then be judged against it. [light] returns this same scheme so a stray light code path
  /// still draws the app correctly rather than falling back to Flutter's defaults.
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,

    primary: Color(0xfff4622a),
    onPrimary: Color(0xffffffff),
    // Solid, for the reason in the class doc — a selected chip is `#F4622A` with white on it.
    primaryContainer: Color(0xfff4622a),
    onPrimaryContainer: Color(0xffffffff),

    // The muted blue-grey the design uses for everything that is present but not shouting.
    secondary: Color(0xffa9bcd1),
    onSecondary: Color(0xff0f2138),
    secondaryContainer: Color(0xff1d3c5a),
    onSecondaryContainer: Color(0xffc6d6e6),

    // Warm amber, and the one colour not taken from the design: it carries «اطلب أكثر وينزل
    // السعر», which has to read as a saving rather than as another orange call to action.
    tertiary: Color(0xffe8a33d),
    onTertiary: Color(0xff0f2138),
    tertiaryContainer: Color(0xff5a4210),
    onTertiaryContainer: Color(0xffffdfa8),

    error: Color(0xffffb4ab),
    onError: Color(0xff690005),
    errorContainer: Color(0xff93000a),
    onErrorContainer: Color(0xffffdad6),

    surface: Color(0xff0f2138),
    onSurface: Color(0xffe8eef5),
    onSurfaceVariant: Color(0xff8fa3ba),
    surfaceTint: Color(0xfff4622a),

    surfaceDim: Color(0xff0a1826),
    surfaceBright: Color(0xff2e5175),
    surfaceContainerLowest: Color(0xff0a1826),
    surfaceContainerLow: Color(0xff132a43),
    surfaceContainer: Color(0xff16304a),
    surfaceContainerHigh: Color(0xff1d3c5a),
    surfaceContainerHighest: Color(0xff24425f),

    // `outline` is what a border has to be *seen*; `outlineVariant` is the card hairline the
    // design draws at `#24425F`.
    outline: Color(0xff5b7a99),
    outlineVariant: Color(0xff24425f),

    shadow: Color(0xff000000),
    scrim: Color(0xff000000),

    inverseSurface: Color(0xffe8eef5),
    onInverseSurface: Color(0xff0f2138),
    inversePrimary: Color(0xff9c3a15),
  );

  ThemeData dark() => theme(darkScheme);

  /// The same scheme. See [darkScheme] — there is no light palette yet.
  ThemeData light() => theme(darkScheme);

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

    // `#132A43` with a `#24425F` hairline above it, and the active item in orange.
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

    // Cards: `#16304A` inside a `#24425F` hairline, 20px corners.
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),

    // 52px tall, 16px corners — the design's one button.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
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

    // Filter chips: 38px, 12px corners, `#16304A` with a `#24425F` edge — and solid orange
    // once chosen.
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      selectedColor: colorScheme.primary,
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
        color: colorScheme.onPrimary,
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
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(color: colorScheme.primary),
  );
}
