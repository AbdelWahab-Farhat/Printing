import 'package:flutter/material.dart';

/// The one colour the generated scheme does not contain: **settled green.**
///
/// Everywhere else in this app the rule holds and is worth restating — colours come out of
/// `ColorScheme`, never out of a `Color(0xff…)` at the call site. `theme.dart` owns every hex in
/// the product; one written into a widget stops matching the moment the palette moves.
///
/// **`StockTone` used to live beside this and has been removed.** It was «تحت الحد» for the
/// staff app's balances screen — a screen this app does not have — and its amber sat a few
/// degrees from the new orange `primary`, so a warning would have read as the app's own accent.
///
/// This file is the deliberate exception, and it is written as an exception rather than as a
/// habit: Material 3 ships three accents and an error, and has **no success role**. «مدفوعة
/// بالكامل» was taking `primary`, which is the same teal as «سعر الطلبية» directly beneath it and
/// as half the app besides — so the one state a person scans a list of orders *for* was drawn in
/// the colour of everything. Green says «انتهى» without being read.
///
/// Kept out of `theme.dart` on purpose: that file is regenerated, and anything added to it is
/// lost the next time somebody re-exports the palette. Kept as an extension on `ColorScheme`
/// rather than a `ThemeExtension` for the same reason — a `ThemeExtension` has to be registered
/// inside the generated `ThemeData`.
///
/// Three values, following the same tonal shape the rest of the scheme uses, so the pair reads
/// correctly in either brightness:
///
/// * [paid] — for text and outlines on a plain surface.
/// * [paidContainer] — the pale fill, «الأخضر الباهت».
/// * [onPaidContainer] — what stays readable on top of that fill.
///
/// **All three sit at 140°.** The band was chosen when `primary` was the staff app's teal, which
/// the green had to be pulled away from; against this app's orange it has an easier job and the
/// values are kept as they are rather than re-tuned for the sake of it.
/// `app_tones_test.dart` pins the band and the distance from `primary` rather than these six
/// values, so the intent survives a change of palette — as it just did.
extension PaymentTone on ColorScheme {
  bool get _isDark => brightness == Brightness.dark;

  Color get paid => _isDark ? const Color(0xff8fd4a6) : const Color(0xff38714b);

  Color get paidContainer => _isDark ? const Color(0xff235032) : const Color(0xffc4ecd1);

  Color get onPaidContainer => _isDark ? const Color(0xffc4ecd1) : const Color(0xff235032);
}

/// The three pill fills the design draws that `ColorScheme` has no role for.
///
/// **Only containers, and that is the whole of the claim.** The design colours one thing with
/// these — the little rounded pill that says where an order or a ticket has got to — and never
/// text on a plain surface. So the extension carries a fill and the ink that survives on it, and
/// nothing else: a `stageAttention` usable as a border or a label would be an invitation to
/// spread a fourth accent through an app that has one.
///
/// * [attentionContainer] — «بانتظار المراجعة», «مفتوحة». The dark orange wash, not
///   `primaryContainer`: that one is the *solid* `#F4622A` this app fills a selected chip with,
///   and a row of solid-orange pills down a list would read as a row of buttons.
/// * [infoContainer] — «قيد التصميم», «قيد المعالجة». Under way, nothing wanted from you.
/// * [pendingContainer] — «جاري التوصيل». Moving, and close.
///
/// «تم الاستلام» and «مغلقة» take [PaymentTone.paidContainer] and the scheme's own
/// `surfaceContainerHigh` respectively. Neither needed a new value, and a stage this app has not
/// heard of takes the neutral one — see `stageTone` in `orders_page.dart`, which is total over
/// `OrderStage` so a colourless pill is impossible.
extension StageTone on ColorScheme {
  bool get _dark => brightness == Brightness.dark;

  Color get attentionContainer => _dark ? const Color(0xff3a2013) : const Color(0xffffdccd);

  Color get onAttentionContainer => _dark ? const Color(0xfff4622a) : const Color(0xff6a2508);

  Color get infoContainer => _dark ? const Color(0xff12304a) : const Color(0xffcfe4f8);

  Color get onInfoContainer => _dark ? const Color(0xff5aa9e6) : const Color(0xff0d3a5c);

  Color get pendingContainer => _dark ? const Color(0xff3a2c10) : const Color(0xfff7e3ba);

  Color get onPendingContainer => _dark ? const Color(0xffe0a83c) : const Color(0xff5a3f05);
}
