import 'package:flutter/material.dart';

/// ثيم النصوص: مقاسات Material 3 بخطّ التطبيق المحزوم.
///
/// **بلا `google_fonts`، عن قصد.** كان يسجّل كل وزنٍ عائلةً مستقلة (`Cairo_regular`،
/// `Cairo_500`) ويعطي كل نمطٍ في الثيم عائلة وزنه. فإذا طلب ويدجت `copyWith(fontWeight: w700)`
/// لم يجد في تلك العائلة إلا الوجه العادي، فثخّنه المحرّك بالحساب — وهكذا خرج كل عريضٍ في التطبيق
/// أنحف مما رسمه التصميم، والشعار والعناوين أوضح ما يكون. العائلة الآن واحدة محزومة بأوزانها
/// الستة (`pubspec.yaml`)، فيجد كل وزنٍ وجهه الحقيقي، ولا شيء يُجلب من الشبكة عند أول فتح.
///
/// [bodyFontString] و[displayFontString] اسما عائلتين في `pubspec.yaml`، لا اسمان في Google Fonts.
TextTheme createTextTheme(BuildContext context, String bodyFontString, String displayFontString) {
  final base = Theme.of(context).textTheme;
  final display = base.apply(fontFamily: displayFontString);
  final body = base.apply(fontFamily: bodyFontString);

  return display.copyWith(
    bodyLarge: body.bodyLarge,
    bodyMedium: body.bodyMedium,
    bodySmall: body.bodySmall,
    labelLarge: body.labelLarge,
    labelMedium: body.labelMedium,
    labelSmall: body.labelSmall,
  );
}
