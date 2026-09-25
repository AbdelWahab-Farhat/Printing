import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// متجرٌ واحد: اسمه، وتحته «بنغازي · الكيش».
///
/// **البطاقة نفسها في مكانين.** في «متاجري» تُلمس فتُعدَّل، وفي خطوة «بيانات الطلب» تُلمس فتُختار —
/// والمختار [AppCard.accent] بإطار العلامة وعلامة صحٍّ في طرفه، لا لونٌ جديد يُخترع للاختيار.
class ShopCard extends StatelessWidget {
  const ShopCard({
    required this.shop,
    this.isSelected = false,
    this.onTap,
    this.trailing,
    super.key,
  });

  final Shop shop;
  final bool isSelected;
  final VoidCallback? onTap;

  /// ما يُرسم في الطرف بدل علامة الاختيار — زرّ الحذف في «متاجري».
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final content = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                shop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (shop.place.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  shop.place,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        if (trailing case final action?)
          action
        else if (isSelected)
          Icon(AppIcons.check, size: 22.sp, color: scheme.primary),
      ],
    );

    final padding = EdgeInsetsDirectional.fromSTEB(14.w, 12.h, trailing == null ? 14.w : 4.w, 12.h);

    return isSelected
        ? AppCard.accent(padding: padding, onTap: onTap, child: content)
        : AppCard(padding: padding, onTap: onTap, child: content);
  }
}
