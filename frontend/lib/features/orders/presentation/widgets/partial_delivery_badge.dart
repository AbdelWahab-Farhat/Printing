import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/partial_delivery_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «استلام جزئي» — أخذ العميل بعض الطلبية وترك الباقي.
///
/// **رماديةٌ بجانب الحمراء.** هذه واقعةٌ عن طلبيةٍ انتهت لا عملٌ ينتظر أحداً، ولونُ الإنذار
/// يجعل من كل طلبيةٍ استلمها صاحبها ناقصةً مشكلةً في قائمةٍ تُقرأ سطراً سطراً. نفس حشوة
/// «مستعجل» ونفس استدارتها، فيستقيم السطر حين تقفان معاً.
///
/// **وبابٌ لا خبر.** كانت تُقرأ ولا تُفتح، والجواب الكامل — كم كان وكم صار، وكم رجع إلى الرفّ،
/// ولماذا — كان موزّعاً على سطر البند وتكلفته وسجلّ حركة المخزون. الضغطة تجمعه في ورقةٍ واحدة:
/// [showPartialDeliverySheet].
///
/// **والأيقونة معها.** كانت بلا أيقونة عمداً — شكلٌ يسبق كلمتين عربيّتين على هاتفٍ عرضه ٣٦٠
/// يأكل من شريط الحالة بجانبه — ثم صارت الشارة باباً، وبابٌ بلا مقبض لا يُعرف أنه باب. والدائرة
/// نصفُ المملوءة هي صورة الكلمة نفسها: بعضٌ أُخذ وبعضٌ بقي.
class PartialDeliveryBadge extends StatelessWidget {
  const PartialDeliveryBadge({required this.order, super.key});

  /// الطلبية كما هي بين يدي الشاشة التي ترسم الشارة. الورقة تقرأ بنودها، ولا تطلب شيئاً من
  /// الخادم: البنود مُحمَّلةٌ مع القائمة ومع الطلبية المفتوحة على السواء. وحده «السبب» يغيب في
  /// القائمة، لأن `transitions` لا تُحمَّل إلا مع الطلبية.
  final Order order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(12.r);

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => showPartialDeliverySheet(context: context, order: order),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.partialDelivery, size: 16.sp, color: scheme.onSurfaceVariant),
              SizedBox(width: 6.w),
              Text(
                'استلام جزئي',
                style: context.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
