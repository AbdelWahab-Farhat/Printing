import 'package:flutter/material.dart';

/// The one colour the scheme does not contain: **settled green**, the logo's third colour.
///
/// Everywhere else in this app the rule holds and is worth restating: colours come out of
/// `ColorScheme`, never out of a `Color(0xff…)` at the call site. `theme.dart` owns the scheme's
/// hexes; one written into a widget stops matching the moment the palette moves.
///
/// This file is the deliberate exception, and it is written as an exception rather than as a
/// habit: Material 3 ships three accents and an error, and has **no success role**. «مدفوعة
/// بالكامل» and «تم الاستلام» are the states a person scans a list of orders *for*, and drawn in
/// the accent they would look like everything else. Green says «انتهى» without being read.
///
/// **It is the logo's green** (`#57937F`, 160°), so all three of the logo's colours have a job:
/// yellow fills, purple draws lines, green says done. The values below are that hue at the
/// lightness each appearance needs.
///
/// Kept as an extension on `ColorScheme` rather than a `ThemeExtension`: a `ThemeExtension` has
/// to be registered inside `ThemeData`, and these are read in places that only hold a scheme.
///
/// * [paid]: for text and outlines on a plain surface.
/// * [paidContainer]: the pale fill, «الأخضر الباهت».
/// * [onPaidContainer]: what stays readable on top of that fill.
///
/// `app_tones_test.dart` pins the band and the distance from `primary` rather than these six
/// values, so the intent survives a change of palette.
extension PaymentTone on ColorScheme {
  bool get _isDark => brightness == Brightness.dark;

  Color get paid => _isDark ? const Color(0xff86cdb3) : const Color(0xff2f6b57);

  Color get paidContainer => _isDark ? const Color(0xff1f4a3c) : const Color(0xffc9ebdd);

  Color get onPaidContainer => _isDark ? const Color(0xffbdebd9) : const Color(0xff1f4a3c);
}

/// The three pill fills the design draws that `ColorScheme` has no role for.
///
/// **Only containers, and that is the whole of the claim.** The design colours one thing with
/// these, the little rounded pill that says where an order or a ticket has got to, and never
/// text on a plain surface. So the extension carries a fill and the ink that survives on it, and
/// nothing else.
///
/// * [attentionContainer]: «بانتظار المراجعة», «مفتوحة». A wash of the brand yellow, not
///   `primaryContainer`: that one is the *solid* yellow this app fills buttons and selected
///   chips with, and a row of solid-yellow pills down a list would read as a row of buttons.
/// * [infoContainer]: «قيد التصميم», «قيد المعالجة». Under way, nothing wanted from you.
/// * [pendingContainer]: «جاري التوصيل». Moving, and close. A wash of the logo's purple; it
///   used to be amber, and amber beside the yellow attention pill read as the same state.
///
/// «تم الاستلام» and «مغلقة» take [PaymentTone.paidContainer] and the scheme's own
/// `surfaceContainerHigh` respectively. A stage this app has not heard of takes the neutral one;
/// see `stageTone` in `stage_pill.dart`, which is total over `OrderStage`.
extension StageTone on ColorScheme {
  bool get _dark => brightness == Brightness.dark;

  Color get attentionContainer => _dark ? const Color(0xff34350f) : const Color(0xfff0f1b5);

  Color get onAttentionContainer => _dark ? const Color(0xffd5d74d) : const Color(0xff4f5100);

  Color get infoContainer => _dark ? const Color(0xff12304a) : const Color(0xffcfe4f8);

  Color get onInfoContainer => _dark ? const Color(0xff5aa9e6) : const Color(0xff0d3a5c);

  Color get pendingContainer => _dark ? const Color(0xff2a2363) : const Color(0xffe4dfff);

  Color get onPendingContainer => _dark ? const Color(0xffb9acff) : const Color(0xff33208f);
}

/// The brand's own surfaces: the account card on «حسابي», and the plate under logos.
///
/// **One value for both appearances.** These are drawn in the brand's colours, not the page's,
/// so they do not change with the time of day, the same way a printed card does not.
///
/// * [brand]: the logo's purple, `#4C29D0`. The account card's far corner.
/// * [brandDeep]: the same hue, darker. The card's gradient ends here, under the text.
/// * [onBrand]: white. 8.3 to 1 on [brand] and 13.6 to 1 on [brandDeep], so the phone number
///   reads at body size anywhere on the card.
///
/// **Purple, not the yellow, and on purpose.** White text cannot sit on yellow, and dark text on
/// a yellow card would make the brand's loudest colour the largest thing on the screen. The
/// logo puts its yellow inside a purple line; the card does the same, with the customer code as
/// the one yellow thing on it.
///
/// `app_tones_test.dart` pins the contrast and the hue, not the values.
extension BrandTone on ColorScheme {
  Color get brand => const Color(0xff4c29d0);

  Color get brandDeep => const Color(0xff2a1880);

  Color get onBrand => const Color(0xffffffff);

  /// The logo's yellow and green, for painting the mark itself (`DaayaMarkPainter`). The yellow
  /// equals `primaryContainer` in both schemes today; it is named here so the mark does not
  /// change colour if the scheme ever does.
  Color get brandYellow => const Color(0xffd5d74d);

  Color get brandGreen => const Color(0xff57937f);

  /// The sheet under a logo: the Daaya mark itself, or a payment method's (ون باي، ليبيانا…).
  /// **White in both appearances**: the logos are drawn for white, and on the night surface the
  /// mark's purple outline and the dark text in «موبي كاش» and «يسر باي» disappear.
  Color get logoPlate => const Color(0xffffffff);
}

/// The band above the sign-in and sign-up screens, and the wallet card; and the text on them.
///
/// **A deep indigo in both appearances, which is why it lives here and not in `ColorScheme`.**
/// No role in the scheme is dark both by day and by night: the dark page is `surface`, and the
/// light scheme's indigo is `onSurface`, a text colour, not a fill.
///
/// * [header]: the logo's purple hue taken almost to black in daylight; at night one step below
///   the page, so the band still reads as a band above it instead of a continuation of it.
/// * [onHeader]: the title and the brand mark's name. White.
/// * [onHeaderVariant]: the line under the title. A lavender, 8 to 1 or better on the band.
///
/// `app_tones_test.dart` pins the hue and the contrast, not the values.
extension HeaderTone on ColorScheme {
  bool get _night => brightness == Brightness.dark;

  Color get header => _night ? const Color(0xff0b0919) : const Color(0xff1b1449);

  Color get onHeader => const Color(0xffffffff);

  Color get onHeaderVariant => const Color(0xffb8b0e8);
}

/// The support chat's colours: my bubble, the support bubble, and what is behind them.
///
/// **Born of a complaint: «الألوان غير واضحة».** The customer's bubble was once the solid brand
/// colour with white text and grey time on it, and the time did not read. So the rule here is
/// what the reference chat app (Telegram) does: **my bubble is a tint of the brand, and the text
/// on it is ink**, not the brand at full strength with white on it.
///
/// * By day: my bubble is a pale lavender with indigo ink, the support bubble is white, and both
///   sit on a backdrop a little darker than the page so the white one's edges show. The hairline
///   around them is the same as on `AppCard`: bubbles separate by fill and hairline, no shadow.
/// * By night: my bubble is a deep purple with white text, the support bubble is indigo.
///
/// **Purple, not the yellow.** A yellow tint by day and an olive by night are two different
/// colours; the logo's purple keeps its hue in both, and the yellow stays the colour of the send
/// button beside it.
///
/// **The time and the read mark are one colour on each bubble**, as in the reference: ✓ and ✓✓
/// differ by count, not by colour. `chat_tone_test.dart` pins the contrast (text 7 to 1, time
/// 4.5 to 1) and the hue, not the values.
extension ChatTone on ColorScheme {
  bool get _chatNight => brightness == Brightness.dark;

  /// What is behind the bubbles, between the title bar and the composer.
  Color get chatBackdrop => _chatNight ? const Color(0xff0b0919) : const Color(0xffecebf5);

  Color get outgoingBubble => _chatNight ? const Color(0xff3a2a8c) : const Color(0xffe6e1ff);

  Color get onOutgoingBubble => _chatNight ? const Color(0xffffffff) : const Color(0xff15122b);

  /// The time and the read mark on my bubble.
  Color get outgoingMeta => _chatNight ? const Color(0xffcfc6ff) : const Color(0xff4c29d0);

  /// My bubble's hairline. None at night: the purple stands out from the indigo on its own.
  Color get outgoingBubbleEdge => _chatNight ? const Color(0x00000000) : const Color(0xffd3cbfa);

  Color get incomingBubble => _chatNight ? const Color(0xff1f1b3e) : const Color(0xffffffff);

  Color get onIncomingBubble => _chatNight ? const Color(0xffeceaf6) : const Color(0xff15122b);

  /// The time on the support bubble.
  Color get incomingMeta => _chatNight ? const Color(0xffa8a3c6) : const Color(0xff5c5880);

  Color get incomingBubbleEdge => _chatNight ? const Color(0x00000000) : const Color(0xffdddaec);
}
