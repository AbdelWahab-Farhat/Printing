import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/bidi.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/dates.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/order_progress.dart';
import 'package:dayaa_client/features/orders/presentation/views/order_progress_bar.dart';
import 'package:dayaa_client/features/orders/presentation/views/stage_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// طلبيةٌ في طريقها، على الرئيسية: رقمها ويومها ومرحلتها، وما فيها ومبلغها، وشريط الخطوات.
///
/// **أصغر من بطاقة «طلباتي» عمداً.** تلك على شكل بطاقة تطبيق الموظفين بتسع خانات وبنودها،
/// وتلك مكانها قائمةٌ تُمسح؛ هنا بطاقاتٌ تحت الإعلانات تجيب عن سؤالٍ واحد: أين وصلت؟
/// والمرحلة بأيقونتها وألوانها نفسها في الاثنتين ([StagePill] و`StageBanner`).
///
/// تُفتح بـ`push`: الطلبية مكانٌ يُذهب إليه ويُرجع منه، فوق الشريط السفلي.
class ActiveOrderCard extends StatelessWidget {
  const ActiveOrderCard({required this.order, super.key});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              // الرقم وحده، بلا «#» — كعنوان الطلبية حين تُفتح.
              order.code,
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (order.placedAt case final placedAt?) ...[
              SizedBox(width: 8.w),
              Text(
                placedAt.relativeDayLabel,
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            const Spacer(),
            StagePill(label: order.stageLabel, stage: order.stage),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: Text(
                order.summary?.bidiSafe ?? 'طلبية',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(width: 10.w),
            // خطٌّ أصغر للعبارة منه للرقم: هي جملةٌ مكان رقم، وبوزن `titleSmall` تعلو على رقم
            // الطلبية.
            Text(
              order.total == null ? awaitingQuoteLabel : '${order.total!.asMoney} د.ل',
              style: order.total == null
                  ? context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)
                  : context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        if (order.stage.step case final step?) ...[
          SizedBox(height: 14.h),
          OrderProgressBar(step: step),
        ],
      ],
    );

    void open() => context.push(Routes.order(order.id));

    // الشعرة البرتقالية على الطلبية التي تريدك: «بانتظار المراجعة» خطوتها للعميل — بأن ينتظر —
    // و«قيد التصميم» قد يُطلب منه فيها شيء.
    return order.stage == OrderStage.underReview || order.stage == OrderStage.designing
        ? AppCard.accent(onTap: open, child: body)
        : AppCard(onTap: open, child: body);
  }
}
