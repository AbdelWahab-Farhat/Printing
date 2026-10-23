import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/svg_icon.dart';
import 'package:dayaa_client/features/social_links/models/social_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// شعار المنصّة بلونها — والمنصّة التي لا نعرفها أيقونةُ رابطٍ بحبر الثيم.
///
/// **بـ[SvgIcon] لا رسماً خاصاً:** الشعار يأخذ مقاسه ولونه من `IconTheme` كأيّ أيقونة، وهذا الويدجت
/// يضع ذلك اللون — لون المنصّة، أو حبر الثيم لشعارٍ أسود لا يُرى على الداكن.
class SocialPlatformMark extends StatelessWidget {
  const SocialPlatformMark(this.platform, {super.key});

  final SocialPlatform platform;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final asset = platform.asset;

    return IconTheme(
      data: IconThemeData(
        size: 22.sp,
        color: platform.brandColor(scheme.brightness) ?? scheme.onSurface,
      ),
      child: asset == null
          ? Icon(AppIcons.link, color: scheme.onSurfaceVariant)
          : SvgIcon(asset),
    );
  }
}
