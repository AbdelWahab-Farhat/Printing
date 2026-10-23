import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/customers/models/social_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// شعارُ منصّة التواصل بلونها، أو أيقونة الرابط العامة لـ[SocialPlatform.other].
///
/// **لونُ المنصّة لا لونُ الحالة.** فيسبوك أزرق على الخانة وفي صفحة العميل، كما يعرفه الناس. وما
/// شعارُه أسود — تيك توك وX — يُرسم بلون الحبر ليُرى في الوضع الداكن، وأصفرُ سناب شات كذلك في الفاتح.
class SocialPlatformIcon extends StatelessWidget {
  const SocialPlatformIcon(this.platform, {required this.size, this.genericColor, super.key});

  final SocialPlatform platform;
  final double size;

  /// لون أيقونة الرابط العامة وحدها — تتبع حالة الخانة (الأحمر حين يكون الرابط خطأ).
  final Color? genericColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final asset = platform.asset;

    if (asset == null) {
      return Icon(AppIcons.link, size: size, color: genericColor ?? scheme.onSurfaceVariant);
    }

    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(_tint(scheme), BlendMode.srcIn),
      // الاسم مكتوبٌ بجانبه دائماً، فالشعار زينةٌ لقارئ الشاشة.
      excludeFromSemantics: true,
    );
  }

  Color _tint(ColorScheme scheme) => switch (platform) {
    SocialPlatform.facebook => const Color(0xFF0866FF),
    SocialPlatform.instagram => const Color(0xFFE4405F),
    SocialPlatform.whatsapp => const Color(0xFF25D366),
    SocialPlatform.telegram => const Color(0xFF26A5E4),
    SocialPlatform.youtube => const Color(0xFFFF0000),
    SocialPlatform.snapchat when scheme.brightness == Brightness.dark => const Color(0xFFFFFC00),
    SocialPlatform.snapchat || SocialPlatform.tiktok || SocialPlatform.x => scheme.onSurface,
    SocialPlatform.other => scheme.onSurfaceVariant,
  };
}
