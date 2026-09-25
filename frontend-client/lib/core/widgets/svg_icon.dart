import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// رسمُ SVG يُعامَل معاملةَ `Icon`: مقاسه ولونه من `IconTheme` الذي حوله.
///
/// **لما لا تملكه Material ولا Cupertino.** ما يوجد في الخطّين يبقى في `AppIcons`، باسمٍ واحدٍ
/// لكلّ فكرة وخطٍّ لكلّ منصّة. وهذه لرسمٍ طلبه المستخدم بعينه، فهو واحدٌ على المنصّتين.
///
/// **اللون من `IconTheme` لا من الملف.** يُصبغ الرسمُ كلّه بلونٍ واحد (`srcIn`)، فيأخذ لونَ الشريط
/// في الوضعين الفاتح والداكن، ولونَ الزرّ المعطّل حين يعطّله `IconButton`، كما تفعل `Icon`. أما
/// الأسودُ في الملف فليُرى الرسمُ حين يُفتح خارج التطبيق.
///
/// **بلا دلالةٍ خاصة بها**، كـ`Icon` بلا `semanticLabel`: الزرّ الذي يحملها يسمّيها بـ`tooltip`.
class SvgIcon extends StatelessWidget {
  const SvgIcon(this.asset, {super.key});

  /// عربة «سلتك» على مثالٍ أرسله المستخدم: سلّةٌ بشبكة، ومقبضٌ في أعلى اليسار، وعجلتان.
  static const String cart = 'assets/icons/cart.svg';

  final String asset;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? 24;
    final opacity = theme.opacity ?? 1;
    final color = theme.color;

    // الشفافيةُ تُضرب في اللون كما تضربها `Icon`، ولا يُمسّ اللون حين لا شفافية.
    final tint = color == null || opacity == 1
        ? color
        : color.withValues(alpha: color.a * opacity);

    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: tint == null ? null : ColorFilter.mode(tint, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}
