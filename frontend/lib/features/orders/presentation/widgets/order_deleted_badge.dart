import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «محذوفة»، بجانب الحالة لا بدلاً منها.
///
/// الطلبية المحذوفة تبقى على الحالة التي حُذفت عليها، ومن يفتحها من الأرشيف أو من إشعار أو من
/// بحث كان يرى «جاهزة» وحدها ولا شيء يقول إنها خرجت من المحل. والسلّة لأنها أيقونة «حذف الطلبية»
/// نفسها: الشارة تقول ما فعله ذلك الزر.
class OrderDeletedBadge extends StatelessWidget {
  const OrderDeletedBadge({this.besideBanner = false, super.key});

  /// مقاس البطاقة في القائمة، حيث تقف بجانب شريط الحالة كما تقف «مستعجل» — لا مقاس الرأس، حيث
  /// تقف بجانب [OrderStatusChip] بأيقونتها. في الحالتين الحشوة والخط من جارتها، فيستقيم السطر
  /// ولا يطول.
  final bool besideBanner;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: besideBanner
          ? EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h)
          : EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(besideBanner ? 12.r : 10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppIcons.delete,
            size: besideBanner ? 16.sp : 17.sp,
            color: scheme.onErrorContainer,
          ),
          SizedBox(width: besideBanner ? 5.w : 6.w),
          Text(
            'محذوفة',
            style: context.textTheme.labelLarge?.copyWith(
              color: scheme.onErrorContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
