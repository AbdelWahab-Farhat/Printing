import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/features/orders/models/order_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// الخطوات الخمس تحت بطاقة الطلبية على الرئيسية: ما مضى وما هي فيه برتقالي، وما بقي باهت، واسم
/// كل خطوةٍ تحتها، والتي هي فيها أثقل.
///
/// **لا يتحرك.** يُرسم حيث تقف الطلبية الآن، ولا يملأ نفسه أمام العين كلما فُتحت الرئيسية.
///
/// ولقارئ الشاشة جملةٌ واحدة بدل خمس كلماتٍ متفرقة: «الخطوة ٣ من ٥: الإنتاج».
///
/// **[pickup] يسمّي الخطوة الأخيرة «استلام مكتب»** بدل «التوصيل» — انظر `OrderStep.labelFor`.
class OrderProgressBar extends StatelessWidget {
  const OrderProgressBar({required this.step, this.pickup = false, super.key});

  final OrderStep step;
  final bool pickup;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    const steps = OrderStep.values;

    Color labelColor(OrderStep each) {
      if (each == step) return scheme.primary;
      if (each.index < step.index) return scheme.onSurfaceVariant;

      return scheme.outline;
    }

    return Semantics(
      label: 'الخطوة ${step.index + 1} من ${steps.length}: ${step.labelFor(pickup: pickup)}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                for (final each in steps) ...[
                  if (each.index > 0) SizedBox(width: 4.w),
                  Expanded(
                    child: Container(
                      height: 6.h,
                      decoration: BoxDecoration(
                        color: each.index <= step.index
                            ? scheme.primary
                            : scheme.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                for (final each in steps) ...[
                  if (each.index > 0) SizedBox(width: 4.w),
                  Expanded(
                    // **يصغر ليتّسع، لا يُقصّ**: «استلام مكتب» أطول من عمودها على هاتفٍ ضيّق،
                    // و«استلام مـ…» لا تقول شيئاً.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        each.labelFor(pickup: pickup),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: labelColor(each),
                          fontWeight: each == step ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
