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

/// الطرف الأعمق من برتقالي العلامة، لتدرّج بطاقة الحساب في «حسابي».
///
/// **لماذا لا يكفي `primary` وحده:** الأبيض على `#F4622A` تباينه ٣٫٢ إلى ١، وهذا يكفي لاسمٍ
/// بخطٍّ كبير ولا يكفي لرقم هاتفٍ بحجم النص. التدرّج يضع النص على هذا الطرف (٤٫٧ إلى ١) ويُبقي
/// البرتقالي الصريح في الزاوية المقابلة، فتبقى البطاقة بلون العلامة ويُقرأ ما عليها. الدرجة نفسها
/// (١٦°)، والإضاءة وحدها أخفض.
///
/// **قيمةٌ واحدة للوضعين:** البطاقة بلون العلامة لا بلون الصفحة، فلا تتبدّل مع المظهر، كما لا
/// يتبدّل `primary` نفسه. `app_tones_test.dart` يثبّت التباين والدرجة، لا القيمة.
extension BrandTone on ColorScheme {
  Color get primaryDeep => const Color(0xffcf410b);
}

/// الترويسة الكحلية فوق شاشتي الدخول وإنشاء الحساب، والنصّ الذي يُكتب عليها.
///
/// **كحليّةٌ في الوضعين، ولذلك هي هنا لا في `ColorScheme`.** لا دور في المخطط يكون كحلياً في
/// النهار والليل معاً: كحليّ الوضع الداكن هو `surface`، وكحليّ الوضع الفاتح هو `onSurface` — لونُ
/// نصٍّ لا خلفية.
///
/// * [header] — `#0F2138` في النهار كما في التصميم؛ وفي الليل أعمق درجةً من الصفحة التي هي
///   `#0F2138` نفسها، كي تبقى الترويسة شريطاً فوق الصفحة لا امتداداً لها.
/// * [onHeader] — العنوان والشعار: أبيض.
/// * [onHeaderVariant] — السطر تحت العنوان، `#9FB0C8` من التصميم.
///
/// `app_tones_test.dart` يثبّت الكحلي والتباين، لا القيم.
extension HeaderTone on ColorScheme {
  bool get _night => brightness == Brightness.dark;

  Color get header => _night ? const Color(0xff0a1826) : const Color(0xff0f2138);

  Color get onHeader => const Color(0xffffffff);

  Color get onHeaderVariant => const Color(0xff9fb0c8);
}

/// ألوان محادثة الدعم: فقاعتي، وفقاعة الدعم، وما خلفهما.
///
/// **وُلدت من شكوى: «الألوان غير واضحة».** كانت فقاعة العميل `primaryContainer` — البرتقالي الصريح
/// — بنصٍّ أبيض تباينه ٣٫٢ إلى ١، ووقتُها بلون `onSurfaceVariant` الرمادي على البرتقالي: ١٫٦ إلى
/// ١، لا يُقرأ. فالقاعدة هنا ما يفعله تطبيق المحادثة المرجع (تيليغرام): **فقاعتي بلون العلامة
/// باهتاً والنصُّ عليها بالحبر**، لا العلامة صريحةً والنصّ أبيض عليها.
///
/// * نهاراً: فقاعتي خوخيّةٌ `#FFE3D4` بالحبر الكحلي، وفقاعة الدعم بيضاء، وكلتاهما على خلفيةٍ
///   أزرق رمادية أغمق قليلاً من الصفحة كي تُرى حوافّ البيضاء. والشعرة حولهما كما في `AppCard`:
///   الفقاعات تنفصل بالتعبئة والشعرة، بلا ظلّ.
/// * ليلاً: فقاعتي برتقاليٌّ محروق `#8F3510` بنصٍّ أبيض (٧٫٨ إلى ١)، وفقاعة الدعم كحليّة.
///
/// **الوقت وعلامة القراءة بلونٍ واحد على كل فقاعة**، كما في المرجع: ✓ و✓✓ تُفرَّقان بعددهما لا
/// بلونهما. `chat_tone_test.dart` يثبّت التباين (النصّ ٧ إلى ١، الوقت ٤٫٥ إلى ١) لا القيم.
extension ChatTone on ColorScheme {
  bool get _chatNight => brightness == Brightness.dark;

  /// ما خلف الفقاعات، بين شريط العنوان وصندوق الكتابة.
  Color get chatBackdrop => _chatNight ? const Color(0xff0a1826) : const Color(0xffecf1f7);

  Color get outgoingBubble => _chatNight ? const Color(0xff8f3510) : const Color(0xffffe3d4);

  Color get onOutgoingBubble => _chatNight ? const Color(0xffffffff) : const Color(0xff0f2138);

  /// الوقت وعلامة القراءة على فقاعتي.
  Color get outgoingMeta => _chatNight ? const Color(0xffffc9b3) : const Color(0xffa8410f);

  /// شعرة فقاعتي. ليلاً لا شعرة: البرتقالي المحروق يبين وحده على الكحلي.
  Color get outgoingBubbleEdge =>
      _chatNight ? const Color(0x00000000) : const Color(0xfff6cdb9);

  Color get incomingBubble => _chatNight ? const Color(0xff1a3652) : const Color(0xffffffff);

  Color get onIncomingBubble => _chatNight ? const Color(0xffe8eef5) : const Color(0xff0f2138);

  /// الوقت على فقاعة الدعم.
  Color get incomingMeta => _chatNight ? const Color(0xff8fa3ba) : const Color(0xff56708c);

  Color get incomingBubbleEdge =>
      _chatNight ? const Color(0x00000000) : const Color(0xffdce5ef);
}
